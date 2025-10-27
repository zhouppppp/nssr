#!/bin/bash

# NSSR 管理脚本
# 用于管理已安装的xboard-node服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否已安装
check_installation() {
    if [[ ! -f /etc/systemd/system/xboard-node.service ]]; then
        echo -e "${RED}xboard-node未安装！请先运行安装脚本。${NC}"
        exit 1
    fi
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}=== 服务状态 ===${NC}"
    systemctl status xboard-node --no-pager -l
    echo ""
    
    if [[ -f /etc/xboard-node/config_info.txt ]]; then
        echo -e "${BLUE}=== 配置信息 ===${NC}"
        cat /etc/xboard-node/config_info.txt
        echo ""
    fi
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}正在重启服务...${NC}"
    systemctl restart xboard-node
    sleep 2
    
    if systemctl is-active --quiet xboard-node; then
        echo -e "${GREEN}服务重启成功！${NC}"
    else
        echo -e "${RED}服务重启失败！${NC}"
        systemctl status xboard-node --no-pager -l
    fi
}

# 查看日志
show_logs() {
    echo -e "${BLUE}=== 最新日志 (按Ctrl+C退出) ===${NC}"
    journalctl -u xboard-node -f --no-pager
}

# 查看实时日志
show_recent_logs() {
    echo -e "${BLUE}=== 最近100行日志 ===${NC}"
    journalctl -u xboard-node -n 100 --no-pager
}

# 修改配置
edit_config() {
    config_file="/etc/xboard-node"
    
    if [[ -f "$config_file/shadowsocks.json" ]]; then
        config_file="$config_file/shadowsocks.json"
        echo -e "${YELLOW}编辑Shadowsocks配置...${NC}"
    elif [[ -f "$config_file/config.json" ]]; then
        config_file="$config_file/config.json"
        echo -e "${YELLOW}编辑Sing-box配置...${NC}"
    else
        echo -e "${RED}未找到配置文件！${NC}"
        exit 1
    fi
    
    # 尝试使用vim，如果没有则使用nano
    if command -v vim >/dev/null 2>&1; then
        vim "$config_file"
    elif command -v nano >/dev/null 2>&1; then
        nano "$config_file"
    else
        echo -e "${YELLOW}请安装vim或nano后重试${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}配置文件已修改，是否重启服务使配置生效？${NC}"
    read -p "重启服务？(y/N): " restart_choice
    if [[ $restart_choice =~ ^[Yy]$ ]]; then
        restart_service
    fi
}

# 端口连通性测试
test_port() {
    port=8388
    echo -e "${BLUE}测试端口 $port 的连通性...${NC}"
    
    if netstat -tlnp | grep ":$port " >/dev/null 2>&1; then
        echo -e "${GREEN}端口 $port 正在监听${NC}"
        
        # 测试本地连接
        if timeout 3 bash -c "echo 'test' | nc localhost $port" >/dev/null 2>&1; then
            echo -e "${GREEN}端口连接测试通过${NC}"
        else
            echo -e "${YELLOW}端口连接测试超时${NC}"
        fi
    else
        echo -e "${RED}端口 $port 未在监听${NC}"
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Xboard节点管理脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status      显示服务状态"
    echo "  restart     重启服务"
    echo "  logs        查看实时日志"
    echo "  recent      查看最近日志"
    echo "  edit        编辑配置文件"
    echo "  test        测试端口连通性"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status      # 查看服务状态"
    echo "  $0 logs        # 查看实时日志"
    echo "  $0 restart     # 重启服务"
}

# 主函数
main() {
    case "${1:-help}" in
        "status")
            check_installation
            show_status
            ;;
        "restart")
            check_installation
            restart_service
            ;;
        "logs")
            check_installation
            show_logs
            ;;
        "recent")
            check_installation
            show_recent_logs
            ;;
        "edit")
            check_installation
            edit_config
            ;;
        "test")
            check_installation
            test_port
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"