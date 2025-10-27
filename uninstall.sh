#!/bin/bash

# NSSR 卸载脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root用户运行此脚本！${NC}"
        exit 1
    fi
}

# 检查是否已安装
check_installation() {
    if [[ ! -f /etc/systemd/system/xboard-node.service ]]; then
        echo -e "${YELLOW}xboard-node未安装，无需卸载。${NC}"
        exit 0
    fi
}

# 停止服务
stop_service() {
    echo -e "${BLUE}正在停止服务...${NC}"
    if systemctl is-active --quiet xboard-node; then
        systemctl stop xboard-node
        echo -e "${GREEN}服务已停止${NC}"
    else
        echo -e "${YELLOW}服务未运行${NC}"
    fi
}

# 禁用服务
disable_service() {
    echo -e "${BLUE}正在禁用服务...${NC}"
    if systemctl is-enabled --quiet xboard-node; then
        systemctl disable xboard-node
        echo -e "${GREEN}服务已禁用${NC}"
    else
        echo -e "${YELLOW}服务未设置为开机自启${NC}"
    fi
}

# 删除systemd服务文件
remove_service_file() {
    echo -e "${BLUE}正在删除服务文件...${NC}"
    if [[ -f /etc/systemd/system/xboard-node.service ]]; then
        rm -f /etc/systemd/system/xboard-node.service
        systemctl daemon-reload
        echo -e "${GREEN}服务文件已删除${NC}"
    fi
}

# 删除配置文件
remove_config() {
    echo -e "${BLUE}正在删除配置文件...${NC}"
    if [[ -d /etc/xboard-node ]]; then
        rm -rf /etc/xboard-node
        echo -e "${GREEN}配置文件已删除${NC}"
    fi
}

# 卸载软件包
uninstall_packages() {
    echo -e "${BLUE}正在卸载相关软件包...${NC}"
    
    # 检测系统类型
    if [[ -f /etc/redhat-release ]]; then
        system_type="centos"
    elif grep -qi ubuntu /etc/os-release || grep -qi debian /etc/os-release; then
        system_type="debian"
    else
        echo -e "${YELLOW}未知系统类型，跳过软件包卸载${NC}"
        return
    fi
    
    # 卸载shadowsocks-libev
    if command -v ss-server >/dev/null 2>&1; then
        if [[ $system_type == "centos" ]]; then
            yum remove -y shadowsocks-libev 2>/dev/null || true
        else
            apt remove -y shadowsocks-libev 2>/dev/null || true
        fi
        echo -e "${GREEN}shadowsocks-libev已卸载${NC}"
    fi
    
    # 卸载simple-obfs
    if command -v obfs-local >/dev/null 2>&1; then
        if [[ $system_type == "centos" ]]; then
            yum remove -y shadowsocks-libev/simple-obfs 2>/dev/null || true
        else
            apt remove -y simple-obfs 2>/dev/null || true
        fi
        echo -e "${GREEN}simple-obfs已卸载${NC}"
    fi
    
    # 删除v2ray-plugin
    if [[ -f /usr/bin/v2ray-plugin ]]; then
        rm -f /usr/bin/v2ray-plugin
        echo -e "${GREEN}v2ray-plugin已删除${NC}"
    fi
    
    # 删除sing-box
    if [[ -f /usr/bin/sing-box ]]; then
        rm -f /usr/bin/sing-box
        echo -e "${GREEN}sing-box已删除${NC}"
    fi
}

# 清理iptables规则
cleanup_firewall() {
    echo -e "${BLUE}正在清理防火墙规则...${NC}"
    
    # 清理iptables规则
    if command -v iptables >/dev/null 2>&1; then
        iptables -D INPUT -p tcp --dport 8388 -j ACCEPT 2>/dev/null || true
        echo -e "${GREEN}iptables规则已清理${NC}"
    fi
    
    # 清理firewalld
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --remove-port=8388/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}firewalld规则已清理${NC}"
    fi
    
    # 清理ufw
    if systemctl is-active --quiet ufw; then
        ufw delete allow 8388/tcp 2>/dev/null || true
        echo -e "${GREEN}ufw规则已清理${NC}"
    fi
}

# 显示卸载完成信息
show_completion_info() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}      Xboard节点卸载完成！${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}卸载完成的项目:${NC}"
    echo "✓ 停止了xboard-node服务"
    echo "✓ 禁用了开机自启"
    echo "✓ 删除了服务文件"
    echo "✓ 删除了配置文件"
    echo "✓ 卸载了相关软件包"
    echo "✓ 清理了防火墙规则"
    echo ""
    echo -e "${BLUE}注意事项:${NC}"
    echo "- 如需重新安装，请重新运行安装脚本"
    echo "- 如果之前配置了其他端口，请手动检查和清理"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      Xboard节点卸载脚本${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    check_root
    check_installation
    
    echo -e "${YELLOW}即将卸载xboard-node及其相关组件...${NC}"
    read -p "确认卸载？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}卸载已取消${NC}"
        exit 0
    fi
    
    stop_service
    disable_service
    remove_service_file
    remove_config
    uninstall_packages
    cleanup_firewall
    
    show_completion_info
}

main "$@"