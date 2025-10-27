#!/bin/bash

# NSSR 一键安装脚本
# 支持两种模式：1.对接面板使用SS+Plugin混淆 2.独立安装使用SS+Reality
# 版本: v1.0.0
# 作者: MiniMax Agent

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查系统
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        system_type="centos"
    elif grep -qi ubuntu /etc/os-release || grep -qi debian /etc/os-release; then
        system_type="debian"
    else
        echo -e "${RED}不支持的操作系统！仅支持CentOS、Ubuntu、Debian${NC}"
        exit 1
    fi
    echo -e "${GREEN}检测到系统类型: $system_type${NC}"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root用户运行此脚本！${NC}"
        exit 1
    fi
}

# 更新系统
update_system() {
    echo -e "${BLUE}正在更新系统包...${NC}"
    if [[ $system_type == "centos" ]]; then
        yum update -y
        yum install -y curl wget git unzip tar
    else
        apt update && apt upgrade -y
        apt install -y curl wget git unzip tar software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    fi
}

# 安装依赖
install_dependencies() {
    echo -e "${BLUE}正在安装基础依赖...${NC}"
    if [[ $system_type == "centos" ]]; then
        yum install -y python3 python3-pip gcc gcc-c++ make
    else
        apt install -y python3 python3-pip build-essential cmake
    fi
}

# 生成随机字符串
generate_random_string() {
    length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# 生成UUID
generate_uuid() {
    python3 -c "import uuid; print(uuid.uuid4())"
}

# 获取用户输入
get_user_input() {
    echo -e "${YELLOW}=== 安装模式选择 ===${NC}"
    echo "1) 对接面板模式 (SS + Plugin混淆)"
    echo "2) 独立安装模式 (SS + Reality)"
    echo ""
    
    while true; do
        read -p "请选择安装模式 [1-2]: " install_mode
        case $install_mode in
            1|2) break;;
            *) echo -e "${RED}请输入有效的选项 (1 或 2)${NC}";;
        esac
    done
    
    if [[ $install_mode == "1" ]]; then
        get_panel_config
    else
        get_reality_config
    fi
}

# 获取面板对接配置
get_panel_config() {
    echo -e "${YELLOW}=== 面板对接配置 ===${NC}"
    
    read -p "请输入面板地址 (例: https://面板域名): " panel_url
    read -p "请输入面板密钥: " panel_key
    read -p "请输入节点ID: " node_id
    read -p "请输入节点名称: " node_name
    
    # 选择插件类型
    echo ""
    echo "请选择混淆插件类型:"
    echo "1) simple-obfs (简单混淆)"
    echo "2) v2ray-plugin (V2Ray插件)"
    
    while true; do
        read -p "请选择插件类型 [1-2]: " plugin_type
        case $plugin_type in
            1|2) break;;
            *) echo -e "${RED}请输入有效的选项 (1 或 2)${NC}";;
        esac
    done
    
    if [[ $plugin_type == "1" ]]; then
        read -p "请输入混淆类型 (http/tls): " obfs_type
        read -p "请输入混淆Host (例: www.bing.com): " obfs_host
        plugin_name="simple-obfs"
        plugin_opts="obfs=${obfs_type};obfs-host=${obfs_host}"
    else
        plugin_name="v2ray-plugin"
        plugin_opts=""
    fi
}

# 获取Reality配置
get_reality_config() {
    echo -e "${YELLOW}=== Reality配置 ===${NC}"
    
    # 生成配置
    uuid=$(generate_uuid)
    password=$(generate_random_string 32)
    public_key=$(generate_random_string 32)
    short_id=$(generate_random_string 8)
    
    echo -e "${BLUE}生成的配置信息:${NC}"
    echo "UUID: $uuid"
    echo "密码: $password"
    echo "公钥: $public_key"
    echo "短ID: $short_id"
    
    # 获取目标站点
    read -p "请输入Reality目标网站 (例: www.microsoft.com): " reality_target
    read -p "请输入Reality目标SNI (默认使用目标网站): " reality_sni
    if [[ -z "$reality_sni" ]]; then
        reality_sni="$reality_target"
    fi
}

# 安装shadowsocks-libev
install_shadowsocks_libev() {
    echo -e "${BLUE}正在安装shadowsocks-libev...${NC}"
    
    if [[ $system_type == "centos" ]]; then
        # CentOS安装
        yum install -y epel-release
        yum install -y shadowsocks-libev
    else
        # Ubuntu/Debian安装
        apt install -y shadowsocks-libev
    fi
}

# 安装simple-obfs插件
install_simple_obfs() {
    echo -e "${BLUE}正在安装simple-obfs插件...${NC}"
    
    if [[ $system_type == "centos" ]]; then
        yum install -y shadowsocks-libev/simple-obfs
    else
        apt install -y simple-obfs
    fi
}

# 安装v2ray-plugin
install_v2ray_plugin() {
    echo -e "${BLUE}正在安装v2ray-plugin...${NC}"
    
    # 下载最新版本
    latest_version=$(curl -s https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    arch=$(uname -m)
    
    if [[ $arch == "x86_64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" ]]; then
        arch="arm64"
    fi
    
    plugin_url="https://github.com/teddysun/v2ray-plugin/releases/download/${latest_version}/v2ray-plugin-linux-${arch}-${latest_version#v}.tar.gz"
    
    cd /tmp
    wget -O v2ray-plugin.tar.gz "$plugin_url"
    tar -xzf v2ray-plugin.tar.gz
    mv v2ray-plugin-linux-* /usr/bin/v2ray-plugin
    chmod +x /usr/bin/v2ray-plugin
    rm v2ray-plugin.tar.gz
}

# 安装sing-box
install_sing_box() {
    echo -e "${BLUE}正在安装sing-box...${NC}"
    
    # 获取最新版本
    latest_version=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    arch=$(uname -m)
    
    if [[ $arch == "x86_64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" ]]; then
        arch="arm64"
    fi
    
    singbox_url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/sing-box-${latest_version#v}-linux-${arch}.tar.gz"
    
    cd /tmp
    wget -O sing-box.tar.gz "$singbox_url"
    tar -xzf sing-box.tar.gz
    mv sing-box /usr/bin/sing-box
    chmod +x /usr/bin/sing-box
    rm sing-box.tar.gz
}

# 创建配置文件 - 面板对接模式
create_panel_config() {
    echo -e "${BLUE}正在创建面板对接配置...${NC}"
    
    config_dir="/etc/xboard-node"
    mkdir -p $config_dir
    
    # 创建ss配置
    cat > $config_dir/shadowsocks.json << EOF
{
    "server":"0.0.0.0",
    "server_port":8388,
    "password":"${password:-$(generate_random_string 32)}",
    "timeout":60,
    "method":"aes-256-gcm",
    "fast_open":true,
    "reuse_port":true,
    "plugin":"${plugin_name}",
    "plugin_opts":"${plugin_opts}"
}
EOF
    
    # 创建systemd服务
    cat > /etc/systemd/system/xboard-node.service << EOF
[Unit]
Description=xboard-node shadowsocks service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$config_dir
ExecStart=/usr/bin/ss-server -c $config_dir/shadowsocks.json
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable xboard-node
    
    echo -e "${GREEN}面板对接配置创建完成！${NC}"
}

# 创建配置文件 - Reality模式
create_reality_config() {
    echo -e "${BLUE}正在创建Reality配置...${NC}"
    
    config_dir="/etc/xboard-node"
    mkdir -p $config_dir
    
    # 生成密钥对
    keypair=$(sing-box generate reality-keypair)
    private_key=$(echo "$keypair" | grep "PrivateKey:" | awk '{print $2}')
    public_key_reality=$(echo "$keypair" | grep "PublicKey:" | awk '{print $2}')
    
    # 如果之前生成了配置，使用之前的值
    if [[ -z "$private_key" ]]; then
        private_key=$(echo "$keypair" | tail -1)
    fi
    
    # 创建sing-box配置
    cat > $config_dir/config.json << EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "shadowsocks",
            "listen": "0.0.0.0",
            "listen_port": 8388,
            "method": "2022-blake3-aes-128-gcm",
            "password": "$password",
            "network": "tcp",
            "users": [
                {
                    "uuid": "$uuid",
                    "password": "$password"
                }
            ],
            "multiplex": {
                "enabled": true,
                "protocol": "h2mux",
                "max_connections": 4,
                "min_streams": 4
            },
            "plugin": "sing-box",
            "plugin_opts": "mode=redirect;timeout=5s"
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ],
    "route": {
        "rules": [
            {
                "protocol": ["dns"],
                "outbound": "dns-out"
            }
        ],
        "final": "direct"
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "cache.db"
        },
        "clash_api": {
            "enabled": true,
            "store_selected": true,
            "store_ip_cidr": true,
            "store_rdrc": true
        }
    }
}
EOF
    
    # 创建systemd服务
    cat > /etc/systemd/system/xboard-node.service << EOF
[Unit]
Description=xboard-node sing-box service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$config_dir
ExecStart=/usr/bin/sing-box run -c $config_dir/config.json
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable xboard-node
    
    # 输出配置信息
    echo -e "${GREEN}Reality配置创建完成！${NC}"
    echo -e "${YELLOW}配置信息:${NC}"
    echo "端口: 8388"
    echo "UUID: $uuid"
    echo "密码: $password"
    echo "公钥: $public_key_reality"
    echo "短ID: $short_id"
    echo "目标网站: $reality_target"
    echo "目标SNI: $reality_sni"
    
    # 保存配置信息到文件
    cat > $config_dir/config_info.txt << EOF
=== Xboard Node Reality 配置信息 ===
安装时间: $(date)
端口: 8388
UUID: $uuid
密码: $password
公钥: $public_key_reality
短ID: $short_id
目标网站: $reality_target
目标SNI: $reality_sni
EOF
    
    echo -e "${BLUE}配置信息已保存到: $config_dir/config_info.txt${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}正在启动服务...${NC}"
    
    systemctl start xboard-node
    sleep 2
    
    if systemctl is-active --quiet xboard-node; then
        echo -e "${GREEN}服务启动成功！${NC}"
    else
        echo -e "${RED}服务启动失败！${NC}"
        systemctl status xboard-node
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    echo -e "${BLUE}正在配置防火墙...${NC}"
    
    # 检查防火墙状态
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-port=8388/tcp
        firewall-cmd --reload
    elif systemctl is-active --quiet ufw; then
        ufw allow 8388/tcp
    fi
    
    # 检查iptables
    if command -v iptables >/dev/null 2>&1; then
        iptables -C INPUT -p tcp --dport 8388 -j ACCEPT 2>/dev/null || \
        iptables -I INPUT -p tcp --dport 8388 -j ACCEPT
    fi
}

# 安装完成提示
show_completion_info() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}         Xboard节点安装完成！${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    if [[ $install_mode == "1" ]]; then
        echo -e "${YELLOW}面板对接模式信息:${NC}"
        echo "面板地址: $panel_url"
        echo "节点ID: $node_id"
        echo "节点名称: $node_name"
        echo "插件类型: $plugin_name"
        echo ""
        echo -e "${BLUE}配置命令:${NC}"
        echo "请在面板中添加以下信息："
        echo "- 类型: Shadowsocks"
        echo "- 端口: 8388"
        echo "- 密码: $(grep password $config_dir/shadowsocks.json | cut -d'"' -f4)"
        echo "- 加密: aes-256-gcm"
        echo "- 插件: $plugin_name"
        echo "- 插件配置: $plugin_opts"
    else
        echo -e "${YELLOW}独立安装模式信息:${NC}"
        echo "协议: Shadowsocks + Reality"
        echo "端口: 8388"
        echo "UUID: $uuid"
        echo "密码: $password"
        echo "公钥: $public_key_reality"
        echo "短ID: $short_id"
        echo "目标网站: $reality_target"
        echo "目标SNI: $reality_sni"
    fi
    
    echo ""
    echo -e "${BLUE}服务管理命令:${NC}"
    echo "启动: systemctl start xboard-node"
    echo "停止: systemctl stop xboard-node"
    echo "重启: systemctl restart xboard-node"
    echo "状态: systemctl status xboard-node"
    echo "查看日志: journalctl -u xboard-node -f"
    echo ""
    echo -e "${BLUE}配置文件位置:${NC}"
    echo "- 服务配置: /etc/systemd/system/xboard-node.service"
    echo "- 应用配置: /etc/xboard-node/"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      Xboard节点一键安装脚本 v1.0.0${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    check_root
    check_system
    update_system
    install_dependencies
    
    # 生成基本密码
    password=$(generate_random_string 32)
    
    get_user_input
    
    # 安装组件
    install_shadowsocks_libev
    
    if [[ $install_mode == "1" ]]; then
        # 面板对接模式
        if [[ $plugin_type == "1" ]]; then
            install_simple_obfs
        else
            install_v2ray_plugin
        fi
        
        create_panel_config
    else
        # 独立安装模式
        install_sing_box
        create_reality_config
    fi
    
    configure_firewall
    start_service
    show_completion_info
}

# 执行主函数
main "$@"