#!/bin/bash

#############################################
# 上传配置文件到服务器
# 
# 功能：
# - 上传 docker-compose.yaml 到服务器
# - 上传 .env 到服务器
#############################################

set -e

# ============ 配置区域 ============
REMOTE_SERVER="43.157.0.135"
REMOTE_USER="root"
REMOTE_DIR="/root/chatwoot"
LOCAL_DIR="/home/chatwoot1/chatwoot"

# SSH密钥路径（如果使用密钥认证）
SSH_KEY="${LOCAL_DIR}/deploy_key"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============ 辅助函数 ============
print_step() { echo -e "${BLUE}===> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ $1${NC}"; }

# ============ 显示帮助信息 ============
show_help() {
    cat << EOF
${GREEN}上传配置文件到服务器${NC}

${CYAN}用法:${NC}
    $0 [选项]

${CYAN}选项:${NC}
    -s, --server SERVER    远程服务器地址 (默认: $REMOTE_SERVER)
    -u, --user USER        远程用户名 (默认: $REMOTE_USER)
    -d, --dir DIR          远程目录 (默认: $REMOTE_DIR)
    -k, --key KEY          SSH密钥路径 (默认: $SSH_KEY)
    -h, --help             显示此帮助信息

${CYAN}示例:${NC}
    # 使用默认配置上传
    $0

    # 指定服务器和用户
    $0 -s 192.168.1.100 -u ubuntu

    # 指定远程目录
    $0 -d /opt/chatwoot

EOF
}

# ============ 解析参数 ============
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            REMOTE_SERVER="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -d|--dir)
            REMOTE_DIR="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# ============ 主程序开始 ============
echo ""
echo "=========================================="
echo -e "${GREEN}上传配置文件到服务器${NC}"
echo "=========================================="
echo ""

# 显示配置信息
print_info "配置信息:"
echo "  远程服务器: $REMOTE_SERVER"
echo "  远程用户: $REMOTE_USER"
echo "  远程目录: $REMOTE_DIR"
echo ""

# 步骤1: 检查本地文件
print_step "步骤 1/4: 检查本地文件"

DOCKER_COMPOSE_FILE="${LOCAL_DIR}/docker-compose.yaml"
ENV_FILE="${LOCAL_DIR}/.env"

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    print_error "文件不存在: $DOCKER_COMPOSE_FILE"
    exit 1
fi
print_success "找到 docker-compose.yaml"

if [ ! -f "$ENV_FILE" ]; then
    print_warning "文件不存在: $ENV_FILE"
    print_info "将只上传 docker-compose.yaml"
    UPLOAD_ENV=false
else
    print_success "找到 .env"
    UPLOAD_ENV=true
fi

# 步骤2: 构建SSH命令
print_step "步骤 2/4: 准备SSH连接"

SSH_OPTS=""
SCP_OPTS=""

if [ -f "$SSH_KEY" ]; then
    SSH_OPTS="-i $SSH_KEY"
    SCP_OPTS="-i $SSH_KEY"
    print_info "使用SSH密钥: $SSH_KEY"
    # 设置密钥权限
    chmod 600 "$SSH_KEY" 2>/dev/null || true
else
    print_info "使用密码认证（将提示输入密码）"
fi

# 步骤3: 测试SSH连接
print_step "步骤 3/4: 测试SSH连接"

if ssh $SSH_OPTS -o ConnectTimeout=10 -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_SERVER "echo 'SSH连接成功'" > /dev/null 2>&1; then
    print_success "SSH连接正常"
else
    print_error "无法连接到远程服务器"
    print_info "请检查："
    echo "  - 服务器地址是否正确: $REMOTE_SERVER"
    echo "  - 用户名是否正确: $REMOTE_USER"
    echo "  - SSH密钥是否正确: $SSH_KEY"
    echo "  - 网络连接是否正常"
    exit 1
fi

# 步骤4: 创建远程目录并传输文件
print_step "步骤 4/4: 传输文件到远程服务器"

# 创建远程目录
ssh $SSH_OPTS $REMOTE_USER@$REMOTE_SERVER "mkdir -p $REMOTE_DIR"
print_success "远程目录已创建/存在"

# 传输 docker-compose.yaml
print_warning "正在传输 docker-compose.yaml..."
if scp $SCP_OPTS "$DOCKER_COMPOSE_FILE" $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/; then
    print_success "docker-compose.yaml 传输完成"
else
    print_error "docker-compose.yaml 传输失败"
    exit 1
fi

# 传输 .env (如果存在)
if [ "$UPLOAD_ENV" = true ]; then
    print_warning "正在传输 .env..."
    if scp $SCP_OPTS "$ENV_FILE" $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/; then
        print_success ".env 传输完成"
    else
        print_error ".env 传输失败"
        exit 1
    fi
fi

# 验证文件
print_info "验证远程文件..."
REMOTE_FILES=$(ssh $SSH_OPTS $REMOTE_USER@$REMOTE_SERVER "ls -lh $REMOTE_DIR/docker-compose.yaml $([ "$UPLOAD_ENV" = true ] && echo "$REMOTE_DIR/.env" || echo "") 2>/dev/null" || echo "")
if [ -n "$REMOTE_FILES" ]; then
    echo "$REMOTE_FILES"
    print_success "文件验证成功"
else
    print_warning "无法验证远程文件，但传输可能已成功"
fi

# 完成
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 文件上传成功！${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}上传的文件:${NC}"
echo "  ✓ docker-compose.yaml -> $REMOTE_DIR/docker-compose.yaml"
[ "$UPLOAD_ENV" = true ] && echo "  ✓ .env -> $REMOTE_DIR/.env"
echo ""
echo -e "${CYAN}下一步操作:${NC}"
echo "  ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose up -d'"
echo ""

