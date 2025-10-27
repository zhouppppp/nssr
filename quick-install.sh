#!/bin/bash

# NSSR 快速安装脚本 (简化版)
# 用于快速部署基本功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查系统
check_system() {
    if [[ ! -f /etc/redhat-release ]] && ! grep -qi ubuntu /etc/os-release && ! grep -qi debian /etc/os-release; then
        echo -e "${RED}不支持的操作系统！${NC}"
        exit 1
    fi
}

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root用户运行此脚本！${NC}"
        exit 1
    fi
}

# 快速安装
quick_install() {
    echo -e "${BLUE}=== 快速安装模式 ===${NC}"
    
    # 更新包管理器
    echo -e "${YELLOW}更新系统包...${NC}"
    if [[ -f /etc/redhat-release ]]; then
        yum update -y
        yum install -y shadowsocks-libev
    else
        apt update && apt install -y shadowsocks-libev
    fi
    
    # 生成配置
    password=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    server_port=8388
    
    # 创建配置
    mkdir -p /etc/xboard-node
    cat > /etc/xboard-node/shadowsocks.json << EOF
{
    "server":"0.0.0.0",
    "server_port":$server_port,
    "password":"$password",
    "timeout":60,
    "method":"aes-256-gcm",
    "fast_open":true,
    "reuse_port":true
}
EOF
    
    # 创建服务
    cat > /etc/systemd/system/xboard-node.service << EOF
[Unit]
Description=xboard-node shadowsocks service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xboard-node
ExecStart=/usr/bin/ss-server -c /etc/xboard-node/shadowsocks.json
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable xboard-node
    
    # 配置防火墙
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=$server_port/tcp
        firewall-cmd --reload
    elif command -v ufw >/dev/null 2>&1; then
        ufw allow $server_port/tcp
    fi
    
    # 启动服务
    systemctl start xboard-node
    
    # 显示信息
    echo ""
    echo -e "${GREEN}快速安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}配置信息:${NC}"
    echo "服务器: $(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP')"
    echo "端口: $server_port"
    echo "密码: $password"
    echo "加密: aes-256-gcm"
    echo ""
    echo -e "${BLUE}管理命令:${NC}"
    echo "启动: systemctl start xboard-node"
    echo "停止: systemctl stop xboard-node"
    echo "状态: systemctl status xboard-node"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Xboard节点快速安装脚本${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    check_root
    check_system
    quick_install
}

main "$@"