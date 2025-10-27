# 项目文件结构

```
nssr/
├── README.md                     # 项目说明文档
├── LICENSE                       # MIT开源协议
├── nssr.sh                     # 主要安装脚本
├── quick-install.sh              # 快速安装脚本
├── manage.sh                     # 节点管理脚本
├── uninstall.sh                  # 卸载脚本
├── .github/
│   └── workflows/
│       └── ci.yml                # GitHub Actions自动化配置
└── docs/
    ├── CHANGELOG.md              # 版本更新记录
    ├── CONTRIBUTING.md           # 贡献指南
    └── TROUBLESHOOTING.md        # 故障排除指南
```

## 脚本功能说明

### 1. install.sh (主要安装脚本)
- **功能**: 完整的安装脚本，支持两种模式
- **模式1**: 对接面板 (SS + Plugin混淆)
- **模式2**: 独立安装 (SS + Reality)
- **特性**: 
  - 交互式安装流程
  - 自动检测系统类型
  - 生成安全配置
  - 配置systemd服务
  - 防火墙自动配置

### 2. quick-install.sh (快速安装)
- **功能**: 简化版安装脚本
- **适用**: 快速部署基本Shadowsocks服务
- **特点**: 
  - 安装速度快
  - 配置简单
  - 功能基础

### 3. manage.sh (管理脚本)
- **功能**: 管理已安装的节点服务
- **命令**: 
  - `./manage.sh status` - 查看服务状态
  - `./manage.sh restart` - 重启服务
  - `./manage.sh logs` - 查看实时日志
  - `./manage.sh recent` - 查看最近日志
  - `./manage.sh edit` - 编辑配置文件
  - `./manage.sh test` - 测试端口连通性

### 4. uninstall.sh (卸载脚本)
- **功能**: 完全卸载xboard-node及其相关组件
- **清理内容**:
  - 停止并禁用服务
  - 删除服务文件
  - 删除配置文件
  - 卸载软件包
  - 清理防火墙规则

## GitHub发布准备

### 1. 创建GitHub仓库
```bash
# 在GitHub上创建新仓库，名称建议：nssr
# 添加描述：Xboard项目节点一键安装脚本
# 设置为Public仓库
```

### 2. 上传代码
```bash
git init
git add .
git commit -m "Initial commit: Xboard节点安装脚本"
git branch -M main
git remote add origin https://github.com/你的用户名/nssr.git
git push -u origin main
```

### 3. 创建发布版本
```bash
# 标签版本
git tag v1.0.0
git push origin v1.0.0

# 或在GitHub界面创建Release
```

### 4. 配置一键安装
将主要安装脚本重命名并设置为raw文件：
```bash
# 将 nssr.sh 设置为安装脚本
# 确保脚本第一行是 #!/bin/bash
```

## 使用方式

### 标准安装
```bash
# 从GitHub直接安装
curl -fsSL https://raw.githubusercontent.com/你的用户名/nssr/main/nssr.sh | bash

# 或下载后执行
wget https://raw.githubusercontent.com/你的用户名/nssr/main/nssr.sh
bash install.sh
```

### 快速安装
```bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/nssr/main/quick-install.sh | bash
```

### 管理节点
```bash
# 下载管理脚本
wget https://raw.githubusercontent.com/你的用户名/nssr/main/manage.sh
chmod +x manage.sh
./manage.sh status
```

## 注意事项

1. **安全考虑**: 脚本需要root权限运行
2. **网络要求**: 需要能够访问GitHub和软件包仓库
3. **系统兼容**: 支持主流Linux发行版
4. **防火墙**: 脚本会自动配置防火墙规则
5. **服务管理**: 使用systemd管理服务

## 贡献指南

1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 技术支持

- **问题反馈**: 通过GitHub Issues
- **功能请求**: 通过GitHub Discussions
- **安全漏洞**: 通过邮件联系维护者

---

**免责声明**: 本项目仅用于学习和技术交流，请遵守当地法律法规。