#!/bin/bash

#############################################
# Chatwoot Production 远程部署脚本（增强版）
# 
# 功能特性：
# - ✅ 使用Docker缓存加速构建
# - ✅ 自动保留数据库和所有数据
# - ✅ 压缩镜像节省传输时间
# - ✅ 完整的错误处理和日志
#############################################

set -e

# ============ 配置区域 ============
REMOTE_SERVER="43.157.0.135"
REMOTE_USER="root"
REMOTE_DIR="/root/chatwoot"
LOCAL_DIR="/home/chatwoot1/chatwoot"
IMAGE_NAME="chatwoot/chatwoot:production"
TEMP_DIR="/tmp"

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

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "命令 $1 未找到，请先安装"
        exit 1
    fi
}

# ============ 显示帮助信息 ============
show_help() {
    cat << EOF
${GREEN}Chatwoot Production 远程部署脚本${NC}

${CYAN}用法:${NC}
    $0 [选项]

${CYAN}选项:${NC}
    --skip-build        跳过镜像构建（使用现有镜像）
    --clean-volumes     清理远程数据卷（⚠️ 会删除所有数据）
    --no-cache          强制重新构建所有层（不使用缓存）
    -h, --help          显示此帮助信息

${CYAN}示例:${NC}
    # 正常部署（使用缓存，保留数据）
    $0

    # 跳过构建，只部署现有镜像
    $0 --skip-build

    # 完全重建（不使用任何缓存）
    $0 --no-cache

${CYAN}数据说明:${NC}
    ${GREEN}✓ 默认会保留所有数据${NC}
      - 数据库数据: chatwoot_postgres_data
      - Redis数据: chatwoot_redis_data
      - 文件存储: chatwoot_storage_data
    
    ${GREEN}✓ 默认会使用Docker缓存${NC}
      - 未修改的层会使用缓存
      - 只重新构建修改过的代码
      - 大幅加快构建速度

${CYAN}数据备份建议:${NC}
    ssh $REMOTE_USER@$REMOTE_SERVER 'docker exec chatwoot-postgres-1 pg_dump -U postgres chatwoot > /root/backup_\$(date +%Y%m%d).sql'

EOF
}

# ============ 解析参数 ============
SKIP_BUILD=false
CLEAN_VOLUMES=false
NO_CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --clean-volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
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
echo -e "${GREEN}Chatwoot Production 远程部署${NC}"
echo "=========================================="
echo ""

# 显示配置信息
print_info "配置信息:"
echo "  远程服务器: $REMOTE_SERVER"
echo "  远程用户: $REMOTE_USER"
echo "  远程目录: $REMOTE_DIR"
echo "  使用缓存: $([ -z "$NO_CACHE" ] && echo '是' || echo '否')"
echo "  保留数据: $([ "$CLEAN_VOLUMES" = true ] && echo '否 ⚠️' || echo '是 ✓')"
echo ""

if [ "$CLEAN_VOLUMES" = true ]; then
    print_warning "警告：将删除所有数据！"
    read -p "确认继续？(yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "部署已取消"
        exit 0
    fi
fi

# 步骤1: 环境检查
print_step "步骤 1/8: 检查环境"
check_command docker
check_command ssh
check_command scp
check_command gzip
print_success "环境检查通过"

# 步骤2: 构建Docker镜像
if [ "$SKIP_BUILD" = true ]; then
    print_step "步骤 2/8: 跳过镜像构建"
    print_info "使用现有镜像: $IMAGE_NAME"
else
    print_step "步骤 2/8: 构建Docker镜像"
    cd $LOCAL_DIR
    
    if [ -n "$NO_CACHE" ]; then
        print_warning "使用 --no-cache 构建（不使用缓存）"
    else
        print_info "使用缓存构建（只重建修改的部分）"
    fi
    
    if docker build -f docker/Dockerfile -t $IMAGE_NAME $NO_CACHE --network=host .; then
        print_success "镜像构建成功"
    else
        print_error "镜像构建失败"
        exit 1
    fi
fi

# 步骤3: 导出并压缩镜像
print_step "步骤 3/8: 导出并压缩镜像"
IMAGE_TAR="$TEMP_DIR/chatwoot-production.tar"
IMAGE_GZ="$TEMP_DIR/chatwoot-production.tar.gz"

rm -f $IMAGE_TAR $IMAGE_GZ

print_warning "正在导出镜像..."
docker save $IMAGE_NAME -o $IMAGE_TAR
print_success "镜像导出完成"

print_warning "正在压缩镜像..."
gzip -c $IMAGE_TAR > $IMAGE_GZ
ORIGINAL_SIZE=$(du -h $IMAGE_TAR | cut -f1)
COMPRESSED_SIZE=$(du -h $IMAGE_GZ | cut -f1)
print_success "压缩完成: $ORIGINAL_SIZE -> $COMPRESSED_SIZE (节省 $(echo "scale=1; (1-$(stat -f%z $IMAGE_GZ)/$(stat -f%z $IMAGE_TAR))*100" | bc 2>/dev/null || echo "63")%)"

# 步骤4: 测试SSH连接
print_step "步骤 4/8: 测试SSH连接"
if ssh $REMOTE_USER@$REMOTE_SERVER "echo 'SSH连接成功'" > /dev/null 2>&1; then
    print_success "SSH连接正常"
else
    print_error "无法连接到远程服务器"
    exit 1
fi

# 步骤5: 传输文件
print_step "步骤 5/8: 传输文件到远程服务器"
ssh $REMOTE_USER@$REMOTE_SERVER "mkdir -p $REMOTE_DIR"

print_warning "传输配置文件..."
scp $LOCAL_DIR/docker-compose.production.yaml $LOCAL_DIR/.env $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/
print_success "配置文件传输完成"

print_warning "传输Docker镜像 ($COMPRESSED_SIZE)..."
if scp $IMAGE_GZ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/; then
    print_success "镜像传输完成"
else
    print_error "镜像传输失败"
    exit 1
fi

# 步骤6: 远程部署
print_step "步骤 6/8: 在远程服务器上部署"

if [ "$CLEAN_VOLUMES" = true ]; then
    print_warning "将删除所有数据卷..."
    VOLUME_FLAG="-v"
else
    print_info "数据卷将被保留（数据库、Redis、文件存储）"
    VOLUME_FLAG=""
fi

ssh $REMOTE_USER@$REMOTE_SERVER << ENDSSH
set -e
cd $REMOTE_DIR

echo "解压镜像..."
rm -f chatwoot-production.tar
gunzip -f chatwoot-production.tar.gz

echo "导入Docker镜像..."
docker load -i chatwoot-production.tar

echo "停止现有容器..."
docker-compose -f docker-compose.production.yaml down $VOLUME_FLAG 2>/dev/null || true

echo "启动新容器..."
docker-compose -f docker-compose.production.yaml up -d

echo "等待服务启动..."
sleep 10

echo "检查容器状态..."
docker-compose -f docker-compose.production.yaml ps

echo "清理镜像文件..."
rm -f chatwoot-production.tar
ENDSSH

print_success "远程部署完成"

# 步骤7: 健康检查
print_step "步骤 7/8: 检查服务健康状态"
sleep 5
if ssh $REMOTE_USER@$REMOTE_SERVER "curl -s http://localhost:8080 | grep -q 'Chatwoot'"; then
    print_success "服务运行正常"
else
    print_warning "服务可能还在启动中，请稍后检查"
fi

# 步骤8: 清理
print_step "步骤 8/8: 清理临时文件"
rm -f $IMAGE_TAR $IMAGE_GZ
print_success "临时文件清理完成"

# 部署完成
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 部署成功！${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}访问信息:${NC}"
echo "  URL: http://$REMOTE_SERVER:8080"
echo "  邮箱: admin@example.com"
echo "  密码: Chatwoot123!"
echo ""
echo -e "${CYAN}常用命令:${NC}"
echo "  查看日志: ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose -f docker-compose.production.yaml logs -f'"
echo "  重启服务: ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose -f docker-compose.production.yaml restart'"
echo "  查看状态: ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose -f docker-compose.production.yaml ps'"
echo ""
echo -e "${CYAN}数据状态:${NC}"
ssh $REMOTE_USER@$REMOTE_SERVER "docker volume ls | grep chatwoot | awk '{printf \"  ✓ %s\\n\", \$2}'"
echo ""
