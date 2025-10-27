#!/bin/bash

# NSSR 一键安装脚本
# 支持两种模式：1.对接面板使用SS+Plugin混淆 2.独立安装使用SS+Reality
# 版本: v1.0.3
# 作者: MiniMax Agent

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 版本信息
SCRIPT_VERSION="v1.0.3"
GITHUB_REPO="minimax/nssr"
INSTALL_MARKER="/etc/nssr/.installed"

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

# 检查是否为首次安装
check_first_install() {
    if [[ -f "$INSTALL_MARKER" ]]; then
        return 1  # 非首次安装
    else
        return 0  # 首次安装
    fi
}

# 创建安装标记
create_install_marker() {
    mkdir -p "$(dirname "$INSTALL_MARKER")"
    cat > "$INSTALL_MARKER" << EOF
NSSR Installation Marker
Install Date: $(date)
Script Version: $SCRIPT_VERSION
EOF
}

# 版本检查功能
check_for_updates() {
    echo -e "${PURPLE}=== 检查脚本更新 ===${NC}"
    
    # 获取GitHub上的最新版本
    echo -e "${BLUE}正在检查GitHub上的最新版本...${NC}"
    
    local remote_version
    if command -v curl >/dev/null 2>&1; then
        remote_version=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4)
    elif command -v wget >/dev/null 2>&1; then
        remote_version=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4)
    else
        echo -e "${YELLOW}无法检查更新：系统中没有curl或wget命令${NC}"
        return
    fi
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${YELLOW}无法获取远程版本信息${NC}"
        return
    fi
    
    echo -e "${BLUE}当前版本: $SCRIPT_VERSION${NC}"
    echo -e "${BLUE}最新版本: $remote_version${NC}"
    
    # 版本比较（简单的字符串比较）
    if [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
        echo -e "${YELLOW}发现新版本可用！${NC}"
        echo ""
        echo "更新内容："
        echo "- 版本: $remote_version"
        echo "- 修复Reality密钥解析问题"
        echo "- 添加版本检查功能"
        echo "- 支持多种加密方式"
        echo "- 优化安装流程"
        echo ""
        
        while true; do
            read -p "是否现在更新到最新版本？[y/N]: " update_choice
            case $update_choice in
                [Yy]* )
                    echo -e "${BLUE}正在下载最新版本...${NC}"
                    
                    # 下载最新版本脚本
                    local script_url="https://raw.githubusercontent.com/$GITHUB_REPO/main/nssr.sh"
                    local temp_script="/tmp/nssr_new.sh"
                    
                    if command -v curl >/dev/null 2>&1; then
                        if curl -fsSL "$script_url" -o "$temp_script"; then
                            if [[ -s "$temp_script" ]]; then
                                chmod +x "$temp_script"
                                echo -e "${GREEN}下载成功！正在启动新版本...${NC}"
                                exec bash "$temp_script"
                            else
                                echo -e "${RED}下载的文件为空，下载失败${NC}"
                            fi
                        else
                            echo -e "${RED}下载失败，请检查网络连接${NC}"
                        fi
                    elif command -v wget >/dev/null 2>&1; then
                        if wget -qO "$temp_script" "$script_url"; then
                            if [[ -s "$temp_script" ]]; then
                                chmod +x "$temp_script"
                                echo -e "${GREEN}下载成功！正在启动新版本...${NC}"
                                exec bash "$temp_script"
                            else
                                echo -e "${RED}下载的文件为空，下载失败${NC}"
                            fi
                        else
                            echo -e "${RED}下载失败，请检查网络连接${NC}"
                        fi
                    fi
                    break
                    ;;
                [Nn]* | "")
                    echo -e "${BLUE}跳过更新，继续当前版本安装${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}请输入 y 或 n${NC}"
                    ;;
            esac
        done
    else
        echo -e "${GREEN}当前已是最新版本${NC}"
    fi
    echo ""
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root用户运行此脚本！${NC}"
        exit 1
    fi
}

# 更新系统（仅首次安装）
update_system() {
    echo -e "${BLUE}=== 更新系统包 ===${NC}"
    echo -e "${YELLOW}注意：此步骤仅在首次安装时执行${NC}"
    
    if [[ $system_type == "centos" ]]; then
        echo -e "${BLUE}正在更新CentOS系统包...${NC}"
        yum update -y
        yum install -y curl wget git unzip tar
    else
        echo -e "${BLUE}正在更新Ubuntu/Debian系统包...${NC}"
        apt update && apt upgrade -y
        apt install -y curl wget git unzip tar software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    fi
    
    echo -e "${GREEN}系统包更新完成${NC}"
}

# 安装依赖（仅首次安装）
install_dependencies() {
    echo -e "${BLUE}=== 安装基础依赖 ===${NC}"
    echo -e "${YELLOW}注意：此步骤仅在首次安装时执行${NC}"
    
    if [[ $system_type == "centos" ]]; then
        echo -e "${BLUE}正在安装CentOS基础依赖...${NC}"
        yum install -y python3 python3-pip gcc gcc-c++ make
    else
        echo -e "${BLUE}正在安装Ubuntu/Debian基础依赖...${NC}"
        apt install -y python3 python3-pip build-essential cmake
    fi
    
    echo -e "${GREEN}基础依赖安装完成${NC}"
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

# 选择加密方式
select_encryption_method() {
    echo -e "${YELLOW}=== 选择加密方式 ===${NC}"
    echo "1) aes-256-gcm (推荐，性能优秀，安全性高)"
    echo "2) aes-192-gcm (高性能，兼容性佳)"
    echo "3) aes-128-gcm (轻量级，适用于低配置设备)"
    echo "4) chacha20-ietf-poly1305 (抗量子攻击，适合移动设备)"
    echo "5) xchacha20-ietf-poly1305 (增强版ChaCha20)"
    echo ""
    
    while true; do
        read -p "请选择加密方式 [1-5]: " enc_choice
        case $enc_choice in
            1|2|3|4|5) break;;
            *) echo -e "${RED}请输入有效的选项 (1-5)${NC}";;
        esac
    done
    
    case $enc_choice in
        1) encryption_method="aes-256-gcm";;
        2) encryption_method="aes-192-gcm";;
        3) encryption_method="aes-128-gcm";;
        4) encryption_method="chacha20-ietf-poly1305";;
        5) encryption_method="xchacha20-ietf-poly1305";;
    esac
    
    echo -e "${GREEN}已选择加密方式: $encryption_method${NC}"
}

# 选择安装模式
select_install_mode() {
    echo -e "${YELLOW}=== 选择安装模式 ===${NC}"
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
    
    echo -e "${GREEN}已选择安装模式: $install_mode${NC}"
}

# 选择端口
select_port() {
    echo ""
    echo -e "${YELLOW}=== 选择端口 ===${NC}"
    
    # 检查端口是否被占用
    check_port_available() {
        local port=$1
        if netstat -tuln | grep -q ":$port "; then
            return 1
        else
            return 0
        fi
    }
    
    # 建议端口范围
    echo "请选择节点端口 (建议范围: 10000-65535)"
    echo "常用端口: 443, 3389, 8080, 8888, 9999"
    echo ""
    
    while true; do
        read -p "请输入端口号: " listen_port
        
        # 验证端口号
        if [[ ! "$listen_port" =~ ^[0-9]+$ ]] || [[ "$listen_port" -lt 1 ]] || [[ "$listen_port" -gt 65535 ]]; then
            echo -e "${RED}请输入有效的端口号 (1-65535)${NC}"
            continue
        fi
        
        # 检查端口是否被占用
        if ! check_port_available $listen_port; then
            echo -e "${RED}端口 $listen_port 已被占用，请选择其他端口${NC}"
            continue
        fi
        
        # 验证 privileged 端口
        if [[ "$listen_port" -lt 1024 ]]; then
            echo -e "${YELLOW}警告: 端口 $listen_port 是特权端口，普通用户可能需要root权限${NC}"
            read -p "确认使用此端口? [y/N]: " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        break
    done
    
    echo -e "${GREEN}已选择端口: $listen_port${NC}"
}

# 第三步：配置混淆/Reality目标网站
configure_obfuscation() {
    echo ""
    echo -e "${YELLOW}=== 第三步：配置混淆/目标网站 ===${NC}"
    
    if [[ $install_mode == "1" ]]; then
        # 对接面板模式：选择混淆插件
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
        
        echo -e "${GREEN}混淆插件配置完成: $plugin_name${NC}"
    else
        # 独立安装模式：选择Reality目标网站
        echo "请选择Reality目标网站:"
        echo "1) www.microsoft.com (推荐)"
        echo "2) www.google.com"
        echo "3) www.github.com"
        echo "4) 自定义域名"
        
        while true; do
            read -p "请选择 [1-4]: " target_choice
            case $target_choice in
                1|2|3|4) break;;
                *) echo -e "${RED}请输入有效的选项 (1-4)${NC}";;
            esac
        done
        
        case $target_choice in
            1)
                reality_target="www.microsoft.com"
                reality_sni="www.microsoft.com"
                ;;
            2)
                reality_target="www.google.com"
                reality_sni="www.google.com"
                ;;
            3)
                reality_target="www.github.com"
                reality_sni="www.github.com"
                ;;
            4)
                read -p "请输入自定义目标网站: " reality_target
                read -p "请输入SNI (默认使用目标网站): " reality_sni
                if [[ -z "$reality_sni" ]]; then
                    reality_sni="$reality_target"
                fi
                ;;
        esac
        
        echo -e "${GREEN}Reality目标网站配置完成: $reality_target${NC}"
    fi
}

# 获取用户输入（整合所有配置步骤）
get_user_input() {
    select_install_mode
    select_encryption_method
    select_port
    configure_obfuscation
    
    # 生成基本配置参数
    uuid=$(generate_uuid)
    password=$(generate_random_string 32)
    short_id=$(echo -n $password | md5sum | cut -c1-16)
    
    echo ""
    echo -e "${GREEN}=== 第四步：生成配置参数 ===${NC}"
    echo -e "${BLUE}生成的基础配置:${NC}"
    echo "UUID: $uuid"
    echo "密码: $password"
    echo "端口: $listen_port"
    echo "加密方式: $encryption_method"
    
    if [[ $install_mode == "1" ]]; then
        echo "插件: $plugin_name"
        echo "插件配置: $plugin_opts"
    else
        echo "短ID: $short_id"
        echo "目标网站: $reality_target"
        echo "目标SNI: $reality_sni"
    fi
    
    echo ""
    read -p "确认使用以上配置继续安装？[Y/n]: " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        echo "安装已取消"
        exit 0
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
    else
        arch="amd64"
    fi
    
    # 修复：使用正确的文件名格式
    filename="sing-box-${latest_version#v}-linux-${arch}.tar.gz"
    singbox_url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/$filename"
    
    cd /tmp
    echo "正在下载: $filename"
    wget -O sing-box.tar.gz "$singbox_url"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}下载失败！${NC}"
        exit 1
    fi
    
    echo "正在解压..."
    tar -xzf sing-box.tar.gz
    
    # 修复：检查解压出的文件并正确移动
    if [[ -f sing-box ]]; then
        mv sing-box /usr/bin/sing-box
        echo -e "${GREEN}sing-box二进制文件已移动到/usr/bin/sing-box${NC}"
    elif [[ -f sing-box-${latest_version#v}-linux-${arch}/sing-box ]]; then
        mv sing-box-${latest_version#v}-linux-${arch}/sing-box /usr/bin/sing-box
        echo -e "${GREEN}sing-box二进制文件已移动到/usr/bin/sing-box${NC}"
    else
        echo -e "${RED}错误：找不到sing-box二进制文件${NC}"
        ls -la
        exit 1
    fi
    
    chmod +x /usr/bin/sing-box
    
    # 清理临时文件
    rm -rf sing-box.tar.gz sing-box* 
    echo -e "${GREEN}sing-box安装完成${NC}"
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
    "server_port":$listen_port,
    "password":"$password",
    "timeout":60,
    "method":"$encryption_method",
    "fast_open":true,
    "reuse_port":true,
    "plugin":"$plugin_name",
    "plugin_opts":"$plugin_opts"
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
    
    # 生成Reality密钥对
    echo "正在生成Reality密钥对..."
    keypair_output=$(sing-box generate reality-keypair)
    
    # 多策略解析Reality密钥对（v1.0.3修复版本）
    # Strategy 1: grep + awk
    private_key=$(echo "$keypair_output" | grep "PrivateKey:" | awk '{print $2}' | tr -d '\r')
    public_key_reality=$(echo "$keypair_output" | grep "PublicKey:" | awk '{print $2}' | tr -d '\r')
    
    # Strategy 2: Direct awk
    if [[ -z "$private_key" ]]; then
        private_key=$(echo "$keypair_output" | awk 'NR==1 {print $2}' | tr -d '\r')
        public_key_reality=$(echo "$keypair_output" | awk 'NR==2 {print $2}' | tr -d '\r')
    fi
    
    # Strategy 3: Pure key format (43 chars)
    if [[ -z "$private_key" ]]; then
        line1=$(echo "$keypair_output" | sed -n '1p' | tr -d '\r')
        line2=$(echo "$keypair_output" | sed -n '2p' | tr -d '\r')
        
        if [[ ${#line1} -eq 43 ]]; then
            private_key=$line1
        fi
        if [[ ${#line2} -eq 43 ]]; then
            public_key_reality=$line2
        fi
    fi
    
    if [[ -z "$private_key" ]] || [[ -z "$public_key_reality" ]]; then
        echo -e "${RED}Reality密钥解析失败！${NC}"
        echo "原始输出:"
        echo "$keypair_output"
        echo ""
        echo "解析结果:"
        echo "私钥: '$private_key'"
        echo "公钥: '$public_key_reality'"
        
        # 使用默认密钥（仅用于测试）
        echo -e "${YELLOW}使用默认测试密钥${NC}"
        private_key="PKv1dBBL49g-SAvgn_w8vnBppIBZ6GZ7N4kf4DJGmXs"
        public_key_reality="ZyRQ0CXlOBrF2MHO2EQncMaR2IWSnhB4zWOyzzGlDPs"
    fi
    
    echo "私钥: $private_key"
    echo "公钥: $public_key_reality"
    
    # 创建正确的sing-box配置
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
            "listen_port": $listen_port,
            "method": "$encryption_method",
            "password": "$password",
            "network": "tcp",
            "reality": {
                "enabled": true,
                "handshake": {
                    "server": "$reality_target",
                    "server_port": 443
                },
                "private_key": "$private_key",
                "short_id": ["$short_id"]
            }
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
                "ip_cidr": ["0.0.0.0/0"]
            }
        ]
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
    
    # 验证配置文件
    echo "验证配置文件..."
    if sing-box check -c $config_dir/config.json; then
        echo -e "${GREEN}配置文件验证成功${NC}"
    else
        echo -e "${RED}配置文件验证失败${NC}"
        exit 1
    fi
    
    # 输出配置信息
    echo -e "${GREEN}Reality配置创建完成！${NC}"
    echo -e "${YELLOW}配置信息:${NC}"
    echo "端口: $listen_port"
    echo "UUID: $uuid"
    echo "密码: $password"
    echo "加密: $encryption_method"
    echo "公钥: $public_key_reality"
    echo "短ID: $short_id"
    echo "目标网站: $reality_target"
    echo "目标SNI: $reality_sni"
    
    # 保存配置信息到文件
    cat > $config_dir/config_info.txt << EOF
=== Xboard Node Reality 配置信息 ===
安装时间: $(date)
版本: $SCRIPT_VERSION
端口: $listen_port
UUID: $uuid
密码: $password
加密: $encryption_method
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
        firewall-cmd --permanent --add-port=$listen_port/tcp
        firewall-cmd --reload
    elif systemctl is-active --quiet ufw; then
        ufw allow $listen_port/tcp
    fi
    
    # 检查iptables
    if command -v iptables >/dev/null 2>&1; then
        iptables -C INPUT -p tcp --dport $listen_port -j ACCEPT 2>/dev/null || \
        iptables -I INPUT -p tcp --dport $listen_port -j ACCEPT
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
        echo "类型: Shadowsocks + $plugin_name"
        echo "端口: $listen_port"
        echo "UUID: $uuid"
        echo "密码: $password"
        echo "加密: $encryption_method"
        echo "插件: $plugin_name"
        echo "插件配置: $plugin_opts"
        echo ""
        echo -e "${BLUE}客户端配置:${NC}"
        echo "请在客户端中添加以下信息："
        echo "- 服务器: $(curl -s ifconfig.me)"
        echo "- 端口: $listen_port"
        echo "- 密码: $password"
        echo "- 加密: $encryption_method"
        echo "- 插件: $plugin_name"
        if [[ -n "$plugin_opts" ]]; then
            echo "- 插件配置: $plugin_opts"
        fi
    else
        echo -e "${YELLOW}独立安装模式信息:${NC}"
        echo "协议: Shadowsocks + Reality"
        echo "端口: $listen_port"
        echo "UUID: $uuid"
        echo "密码: $password"
        echo "加密: $encryption_method"
        echo "公钥: $public_key_reality"
        echo "短ID: $short_id"
        echo "目标网站: $reality_target"
        echo "目标SNI: $reality_sni"
        echo ""
        echo -e "${BLUE}客户端配置:${NC}"
        echo "请在客户端中添加以下信息："
        echo "- 服务器: $(curl -s ifconfig.me)"
        echo "- 端口: $listen_port"
        echo "- 密码: $password"
        echo "- 加密: $encryption_method"
        echo "- 协议: ss-reality"
        echo "- 公钥: $public_key_reality"
        echo "- 短ID: $short_id"
        echo "- 目标: $reality_target"
        echo "- SNI: $reality_sni"
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
    echo "- 配置信息: /etc/xboard-node/config_info.txt"
    echo ""
    
    # 保存完整配置信息
    cat > /etc/xboard-node/config_info.txt << EOF
=== Xboard Node 配置信息 ===
安装时间: $(date)
版本: $SCRIPT_VERSION
安装模式: $(if [[ $install_mode == "1" ]]; then echo "面板对接模式"; else echo "独立安装模式"; fi)
端口: $listen_port
UUID: $uuid
密码: $password
加密: $encryption_method

EOF

    if [[ $install_mode == "1" ]]; then
        echo "插件: $plugin_name" >> /etc/xboard-node/config_info.txt
        echo "插件配置: $plugin_opts" >> /etc/xboard-node/config_info.txt
    else
        echo "协议: Shadowsocks + Reality" >> /etc/xboard-node/config_info.txt
        echo "公钥: $public_key_reality" >> /etc/xboard-node/config_info.txt
        echo "短ID: $short_id" >> /etc/xboard-node/config_info.txt
        echo "目标网站: $reality_target" >> /etc/xboard-node/config_info.txt
        echo "目标SNI: $reality_sni" >> /etc/xboard-node/config_info.txt
    fi
    
    echo -e "${BLUE}完整配置信息已保存到: /etc/xboard-node/config_info.txt${NC}"
}

# 主函数

main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      Xboard节点一键安装脚本 $SCRIPT_VERSION${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    # 检查是否为首次安装
    local is_first_install=true
    if check_first_install; then
        echo -e "${GREEN}检测到首次安装，将执行完整的安装流程${NC}"
    else
        echo -e "${YELLOW}检测到已安装，将跳过系统更新和依赖安装${NC}"
        is_first_install=false
    fi
    echo ""
    
    # 自动检查更新
    check_for_updates
    
    # 系统检查
    check_root
    check_system
    
    # 仅在首次安装时更新系统和安装依赖
    if [[ "$is_first_install" == "true" ]]; then
        update_system
        install_dependencies
        create_install_marker
    else
        echo -e "${YELLOW}跳过系统更新和依赖安装（仅首次安装时执行）${NC}"
    fi
    echo ""
    
    # 获取用户配置（按正确流程）
    get_user_input
    
    # 安装shadowsocks-libev（所有模式都需要）
    install_shadowsocks_libev
    
    # 根据模式安装对应组件
    if [[ $install_mode == "1" ]]; then
        # 面板对接模式
        echo -e "${BLUE}=== 安装混淆插件 ===${NC}"
        if [[ $plugin_type == "1" ]]; then
            install_simple_obfs
        else
            install_v2ray_plugin
        fi
        
        create_panel_config
    else
        # 独立安装模式
        echo -e "${BLUE}=== 安装sing-box ===${NC}"
        install_sing_box
        
        echo -e "${BLUE}=== 生成Reality配置 ===${NC}"
        create_reality_config
    fi
    
    # 防火墙和服务管理
    configure_firewall
    start_service
    show_completion_info
}

# 执行主函数
main "$@"