# NSSR 一键安装脚本

## 项目简介

这是一个专为Xboard项目设计的节点安装脚本，支持两种安装模式：

1. **对接面板模式**: 使用Shadowsocks + Plugin混淆，与V2Board/Xboard面板对接
2. **独立安装模式**: 使用Shadowsocks + Reality，基于Sing-box内核

## 特性

- ✅ 支持CentOS、Ubuntu、Debian系统
- ✅ 交互式安装流程，简单易用
- ✅ 自动生成安全配置
- ✅ 支持多种混淆插件（simple-obfs、v2ray-plugin）
- ✅ Reality协议支持，流量伪装
- ✅ 自动配置systemd服务
- ✅ 防火墙自动配置
- ✅ 完整的服务管理命令

## 安装方式

### 标准安装

```bash
# 下载并执行安装脚本
curl -fsSL https://raw.githubusercontent.com/zhouppppp/nssr/main/nssr.sh | bash

# 或者使用wget
wget -qO- https://raw.githubusercontent.com/zhouppppp/nssr/main/nssr.sh | bash
```

### 备用安装方式

```bash
# 克隆仓库
git clone https://github.com/你的用户名/nssr.git
cd nssr

# 执行安装脚本
chmod +x xboard-node-installer.sh
./xboard-node-installer.sh
```

## 使用说明

### 安装步骤

1. **运行脚本**: 以root权限运行安装脚本
2. **选择模式**: 
   - 输入 `1` 选择对接面板模式
   - 输入 `2` 选择独立安装模式
3. **配置参数**: 根据提示输入相应配置信息
4. **等待安装**: 脚本将自动完成安装和配置

### 配置选项

#### 对接面板模式
- 面板地址 (如: https://面板域名)
- 面板密钥
- 节点ID
- 节点名称
- 插件类型 (simple-obfs 或 v2ray-plugin)
- 混淆配置

#### 独立安装模式
- 目标网站 (Reality伪装目标)
- SNI配置 (可选，默认使用目标网站)

## 服务管理

安装完成后，使用以下命令管理服务：

```bash
# 启动服务
systemctl start xboard-node

# 停止服务
systemctl stop xboard-node

# 重启服务
systemctl restart xboard-node

# 查看状态
systemctl status xboard-node

# 查看日志
journalctl -u xboard-node -f

# 开机自启
systemctl enable xboard-node
```

## 配置文件位置

- **服务配置**: `/etc/systemd/system/xboard-node.service`
- **应用配置**: `/etc/xboard-node/`
- **配置信息**: `/etc/xboard-node/config_info.txt` (仅独立安装模式)

## 支持的协议

### 对接面板模式
- **协议**: Shadowsocks
- **加密**: aes-256-gcm
- **插件**: 
  - simple-obfs (支持 http/tls 混淆)
  - v2ray-plugin (V2Ray websocket混淆)

### 独立安装模式
- **协议**: Shadowsocks + Reality
- **内核**: Sing-box
- **加密**: 2022-blake3-aes-128-gcm
- **伪装**: Reality协议

## 系统要求

- **操作系统**: CentOS 7+, Ubuntu 16+, Debian 9+
- **架构**: x86_64, ARM64
- **权限**: root用户
- **内存**: 至少512MB
- **磁盘**: 至少1GB可用空间

## 故障排除

### 常见问题

1. **端口无法访问**
   ```bash
   # 检查防火墙配置
   iptables -L -n | grep 8388
   
   # 临时关闭防火墙测试
   systemctl stop firewalld  # CentOS
   ufw disable               # Ubuntu
   ```

2. **服务启动失败**
   ```bash
   # 查看详细日志
   journalctl -u xboard-node -l
   
   # 检查配置文件
   cat /etc/xboard-node/config.json
   ```

3. **权限问题**
   ```bash
   # 确保脚本以root权限运行
   sudo ./xboard-node-installer.sh
   
   # 检查文件权限
   ls -la /etc/xboard-node/
   ```

### 卸载

```bash
# 停止并禁用服务
systemctl stop xboard-node
systemctl disable xboard-node

# 删除服务文件
rm -f /etc/systemd/system/xboard-node.service
systemctl daemon-reload

# 删除配置文件
rm -rf /etc/xboard-node

# 卸载软件包 (可选)
# yum remove shadowsocks-libev    # CentOS
# apt remove shadowsocks-libev    # Ubuntu/Debian
```

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License

## 联系方式

如有问题或建议，请通过GitHub Issues联系我们。

---

**免责声明**: 本脚本仅用于学习和技术交流，请遵守当地法律法规。
