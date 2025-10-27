#!/bin/bash

# NSSR 项目快速上传到GitHub脚本
# 使用方法: ./upload-to-github.sh YOUR_USERNAME

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供GitHub用户名${NC}"
    echo "使用方法: $0 YOUR_USERNAME"
    exit 1
fi

USERNAME=$1
REPO_NAME="nssr"
REPO_URL="https://github.com/$USERNAME/$REPO_NAME.git"

echo -e "${BLUE}=== NSSR 项目GitHub上传脚本 ===${NC}"
echo -e "GitHub用户名: ${GREEN}$USERNAME${NC}"
echo -e "仓库名称: ${GREEN}$REPO_NAME${NC}"
echo -e "仓库地址: ${GREEN}$REPO_URL${NC}"
echo

# 检查Git是否安装
if ! command -v git &> /dev/null; then
    echo -e "${RED}错误: Git未安装${NC}"
    echo "请先安装Git:"
    echo "CentOS/RHEL: sudo yum install git"
    echo "Ubuntu/Debian: sudo apt-get install git"
    exit 1
fi

# 初始化Git仓库
echo -e "${YELLOW}步骤1: 初始化Git仓库${NC}"
git init
echo -e "${GREEN}✓ Git仓库初始化完成${NC}"

# 添加文件
echo -e "${YELLOW}步骤2: 添加文件到Git${NC}"
git add .
echo -e "${GREEN}✓ 文件添加完成${NC}"

# 首次提交
echo -e "${YELLOW}步骤3: 创建初始提交${NC}"
git commit -m "Initial commit: NSSR一键安装脚本"
echo -e "${GREEN}✓ 初始提交完成${NC}"

# 设置主分支
echo -e "${YELLOW}步骤4: 设置主分支${NC}"
git branch -M main
echo -e "${GREEN}✓ 主分支设置完成${NC}"

# 添加远程仓库
echo -e "${YELLOW}步骤5: 连接GitHub仓库${NC}"
if git remote get-url origin &> /dev/null; then
    echo -e "${YELLOW}远程仓库已存在，正在更新...${NC}"
    git remote set-url origin $REPO_URL
else
    git remote add origin $REPO_URL
fi
echo -e "${GREEN}✓ 远程仓库连接完成${NC}"

# 推送到GitHub
echo -e "${YELLOW}步骤6: 推送到GitHub${NC}"
echo -e "${YELLOW}提示: 如果是首次推送，系统会要求输入GitHub凭据${NC}"
echo

# 尝试推送
if git push -u origin main 2>/dev/null; then
    echo -e "${GREEN}✓ 代码推送成功！${NC}"
else
    echo -e "${RED}推送失败，可能需要认证${NC}"
    echo
    echo -e "${YELLOW}请选择认证方式:${NC}"
    echo "1) 使用Personal Access Token (推荐)"
    echo "2) 使用GitHub CLI"
    echo "3) 手动复制命令执行"
    
    read -p "请选择 [1-3]: " auth_choice
    
    case $auth_choice in
        1)
            echo -e "${YELLOW}使用Personal Access Token认证:${NC}"
            echo "1. 访问 https://github.com/settings/tokens"
            echo "2. 创建新的Personal Access Token (classic)"
            echo "3. 勾选 'repo' 权限"
            echo "4. 复制token并使用以下命令:"
            echo -e "${GREEN}git remote set-url origin https://$USERNAME:YOUR_TOKEN@github.com/$USERNAME/$REPO_NAME.git${NC}"
            echo -e "${GREEN}git push -u origin main${NC}"
            ;;
        2)
            echo -e "${YELLOW}使用GitHub CLI认证:${NC}"
            echo "1. 安装GitHub CLI: https://cli.github.com/"
            echo "2. 运行: gh auth login"
            echo "3. 运行: gh repo create $REPO_NAME --public"
            echo "4. 运行: git push -u origin main"
            ;;
        3)
            echo -e "${YELLOW}手动执行以下命令:${NC}"
            echo -e "${GREEN}git remote set-url origin $REPO_URL${NC}"
            echo -e "${GREEN}git push -u origin main${NC}"
            ;;
    esac
fi

echo
echo -e "${GREEN}=== 上传完成！ ===${NC}"
echo -e "仓库地址: ${BLUE}$REPO_URL${NC}"
echo -e "一键安装命令:"
echo -e "${GREEN}curl -fsSL $REPO_URL/raw/main/nssr.sh | bash${NC}"
echo
echo -e "${YELLOW}后续步骤:${NC}"
echo "1. 访问GitHub仓库检查文件"
echo "2. 创建v1.0.0发布版本"
echo "3. 添加仓库描述和标签"
echo "4. 启用Issues功能"

# 创建发布版本提示
echo
read -p "是否现在创建发布版本? [y/N]: " create_release
if [[ $create_release =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}请手动创建发布版本:${NC}"
    echo "1. 访问: $REPO_URL/releases"
    echo "2. 点击 'Create a new release'"
    echo "3. 标签版本: v1.0.0"
    echo "4. 发布标题: NSSR v1.0.0"
    echo "5. 描述: 首个正式版本发布！"
fi

echo -e "${GREEN}脚本执行完成！${NC}"