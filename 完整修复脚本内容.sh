#!/bin/bash
# NSSR 快速修复脚本
# 解决sing-box安装问题

echo "==================================="
echo "    NSSR 一键修复脚本 v1.0.1"
echo "==================================="
echo ""

# 检查是否以root用户运行
if [[ $EUID -ne 0 ]]; then
   echo "错误：请使用root用户运行此脚本"
   echo "请执行：sudo su"
   exit 1
fi

# 检查操作系统
if [[ -f /etc/redhat-release ]]; then
    system_type="centos"
elif grep -qi ubuntu /etc/os-release || grep -qi debian /etc/os-release; then
    system_type="debian"
else
    echo "错误：不支持的操作系统"
    exit 1
fi

echo "检测到系统类型: $system_type"
echo ""

# 安装依赖
echo "步骤1: 安装系统依赖..."
if [[ $system_type == "centos" ]]; then
    yum update -y
    yum install -y curl wget git unzip tar python3 python3-pip shadowsocks-libev simple-obfs
else
    apt update && apt upgrade -y
    apt install -y curl wget git unzip tar python3 python3-pip shadowsocks-libev simple-obfs
fi

echo "✓ 系统依赖安装完成"
echo ""

# 安装sing-box (修复版)
echo "步骤2: 安装sing-box..."
latest_version=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep "tag_name" | cut -d '"' -f 4)
arch=$(uname -m)

if [[ $arch == "x86_64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" ]]; then
    arch="arm64"
else
    arch="amd64"
fi

filename="sing-box-${latest_version#v}-linux-${arch}.tar.gz"
singbox_url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/$filename"

cd /tmp
echo "正在下载: $filename"
wget -O sing-box.tar.gz "$singbox_url"

if [[ $? -eq 0 ]]; then
    echo "✓ 下载成功"
else
    echo "✗ 下载失败"
    exit 1
fi

echo "正在解压..."
tar -xzf sing-box.tar.gz

# 检查解压结果并正确移动文件
echo "检查解压结果..."
if [[ -f sing-box ]]; then
    mv sing-box /usr/bin/sing-box
    echo "✓ 找到sing-box二进制文件，已移动到/usr/bin/sing-box"
elif [[ -f sing-box-${latest_version#v}-linux-${arch}/sing-box ]]; then
    mv sing-box-${latest_version#v}-linux-${arch}/sing-box /usr/bin/sing-box
    echo "✓ 找到sing-box二进制文件，已移动到/usr/bin/sing-box"
else
    echo "✗ 错误：找不到sing-box二进制文件"
    echo "当前目录内容："
    ls -la
    exit 1
fi

chmod +x /usr/bin/sing-box

# 清理临时文件
rm -rf sing-box.tar.gz sing-box*

echo "✓ sing-box安装完成"
echo ""

# 验证安装
echo "步骤3: 验证安装..."
if command -v sing-box >/dev/null 2>&1; then
    echo "✓ sing-box版本: $(sing-box version | head -n1)"
else
    echo "✗ sing-box安装失败"
    exit 1
fi

if command -v ss-server >/dev/null 2>&1; then
    echo "✓ shadowsocks-libev已安装"
else
    echo "✗ shadowsocks-libev未安装"
fi

echo ""
echo "==================================="
echo "    修复完成！"
echo "==================================="
echo ""
echo "现在您可以运行完整的安装脚本了："
echo ""
echo "1. 下载完整脚本："
echo "   curl -fsSL https://raw.githubusercontent.com/zhouppppp/nssr/main/nssr.sh -o nssr.sh"
echo ""
echo "2. 运行脚本："
echo "   chmod +x nssr.sh"
echo "   bash nssr.sh"
echo ""
echo "或者直接下载修复版："
echo "   curl -fsSL https://raw.githubusercontent.com/zhouppppp/nssr/main/fix-nssr.sh -o nssr.sh"
echo ""