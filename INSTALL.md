# 安装指南

## 快速开始

### 一键安装 (推荐)

```bash
# 标准安装脚本 (支持两种模式)
curl -fsSL https://raw.githubusercontent.com/你的用户名/nssr/main/nssr.sh | bash

# 快速安装 (仅基础Shadowsocks)
curl -fsSL https://raw.githubusercontent.com/你的用户名/nssr/main/quick-install.sh | bash
```

### 手动安装

```bash
# 1. 克隆项目
git clone https://github.com/你的用户名/nssr.git
cd nssr

# 2. 添加执行权限
chmod +x *.sh

# 3. 运行安装脚本
./install.sh
```

## 安装步骤详解

### 步骤1: 系统检查

脚本会自动检查以下内容：
- 操作系统类型 (CentOS/Ubuntu/Debian)
- 用户权限 (必须是root)
- 网络连接状态

### 步骤2: 模式选择

```
请选择安装模式:
1) 对接面板模式 (SS + Plugin混淆)
2) 独立安装模式 (SS + Reality)

请选择安装模式 [1-2]:
```

**选择说明**:
- 选择 `1`: 用于与V2Board/Xboard面板对接
- 选择 `2`: 独立部署使用Reality协议

### 步骤3: 配置参数

#### 对接面板模式参数
- 面板地址: 如 `https://yourpanel.com`
- 面板密钥: 从面板获取的API密钥
- 节点ID: 面板中创建的节点ID
- 节点名称: 自定义节点名称
- 插件类型: simple-obfs 或 v2ray-plugin

#### 独立安装模式参数
- 目标网站: Reality伪装的目标网站 (如: `www.microsoft.com`)
- SNI配置: 通常与目标网站相同

### 步骤4: 自动安装

脚本将自动完成：
- 更新系统包
- 安装必要依赖
- 下载并配置软件
- 创建systemd服务
- 配置防火墙规则
- 启动服务

### 步骤5: 安装完成

安装完成后会显示：
- 服务配置信息
- 客户端连接参数
- 管理命令说明
- 配置文件位置

## 详细配置说明

### 对接面板模式配置

#### 1. 插件类型选择

**simple-obfs插件**:
```json
{
  "plugin": "simple-obfs",
  "plugin_opts": "obfs=http;obfs-host=www.bing.com"
}
```

**v2ray-plugin插件**:
```json
{
  "plugin": "v2ray-plugin",
  "plugin_opts": ""
}
```

#### 2. 面板对接设置

在V2Board/Xboard面板中添加节点时使用：
- **类型**: Shadowsocks
- **地址**: 服务器IP
- **端口**: 8388 (默认)
- **加密**: aes-256-gcm
- **密码**: 脚本生成的随机密码
- **插件**: 根据选择的插件类型配置

### 独立安装模式配置

#### 1. Reality协议参数

```
=== Reality配置信息 ===
UUID: 12345678-1234-1234-1234-123456789abc
密码: randomly_generated_password
公钥: public_key_base64_string
短ID: short_id_8chars
目标网站: www.microsoft.com
目标SNI: www.microsoft.com
```

#### 2. 客户端配置

在支持Reality的客户端中配置：
- **协议**: Shadowsocks
- **服务器**: 服务器IP
- **端口**: 8388
- **加密**: 2022-blake3-aes-128-gcm
- **密码**: 生成的UUID
- **插件**: sing-box Reality

## 高级配置

### 自定义端口

如需修改默认端口8388：

1. **编辑配置文件**:
```bash
# 编辑ss配置
vim /etc/xboard-node/shadowsocks.json

# 或编辑sing-box配置
vim /etc/xboard-node/config.json
```

2. **重启服务**:
```bash
systemctl restart xboard-node
```

3. **更新防火墙**:
```bash
# CentOS
firewall-cmd --permanent --add-port=新端口/tcp
firewall-cmd --reload

# Ubuntu/Debian
ufw allow 新端口/tcp
```

### 性能优化

#### 1. 启用TCP Fast Open
```json
{
  "fast_open": true,
  "reuse_port": true
}
```

#### 2. BBR拥塞控制
```bash
# 启用BBR
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p
```

#### 3. 文件描述符限制
```bash
# 编辑limits.conf
echo "root soft nofile 65535" >> /etc/security/limits.conf
echo "root hard nofile 65535" >> /etc/security/limits.conf
```

## 常见问题解决

### 1. 安装失败

**问题**: 提示权限不足
```bash
# 解决: 确保使用root权限
sudo bash install.sh
```

**问题**: 网络连接失败
```bash
# 解决: 检查网络和DNS
ping github.com
nslookup raw.githubusercontent.com
```

### 2. 服务启动失败

**问题**: 端口被占用
```bash
# 检查端口占用
netstat -tlnp | grep 8388

# 修改配置文件中的端口
vim /etc/xboard-node/shadowsocks.json
```

**问题**: 配置文件错误
```bash
# 查看详细错误
journalctl -u xboard-node -l

# 验证JSON格式
python3 -m json.tool /etc/xboard-node/shadowsocks.json
```

### 3. 连接问题

**问题**: 客户端无法连接
```bash
# 检查服务状态
systemctl status xboard-node

# 检查防火墙
iptables -L -n | grep 8388
firewall-cmd --list-ports

# 测试端口连通性
nc -zv 服务器IP 8388
```

**问题**: 速度慢或不稳定
```bash
# 启用BBR
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p

# 重启服务
systemctl restart xboard-node
```

## 最佳实践

### 1. 安全建议
- 定期更换密码和UUID
- 使用强加密算法
- 配置防火墙限制访问
- 定期更新系统和软件

### 2. 性能建议
- 启用TCP Fast Open
- 使用BBR拥塞控制
- 适当调整缓冲区大小
- 监控资源使用情况

### 3. 维护建议
- 定期查看日志
- 监控服务状态
- 备份配置文件
- 测试连接稳定性

---

如果遇到问题，请查看[故障排除指南](TROUBLESHOOTING.md)或提交[GitHub Issue](https://github.com/你的用户名/nssr/issues)。