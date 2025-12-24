#!/bin/bash

#############################################
# Chatwoot Production 远程部署脚本
# 用途: 构建并部署Chatwoot到远程服务器
#############################################

set -e  # 遇到错误立即退出

# 配置变量
REMOTE_SERVER="43.157.0.135"
REMOTE_USER="root"
REMOTE_DIR="/root/chatwoot"
LOCAL_DIR="/home/chatwoot1/chatwoot"
IMAGE_NAME="chatwoot/chatwoot:production"
TEMP_DIR="/tmp"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "命令 $1 未找到，请先安装"
        exit 1
    fi
}

# 步骤1: 环境检查
print_step "步骤 1/8: 检查环境"
check_command docker
check_command ssh
check_command scp
check_command gzip
print_success "环境检查通过"

# 步骤2: 构建Docker镜像
print_step "步骤 2/8: 构建Docker镜像"
cd $LOCAL_DIR
if docker build -f docker/Dockerfile -t $IMAGE_NAME --network=host .; then
    print_success "镜像构建成功"
else
    print_error "镜像构建失败"
    exit 1
fi

# 步骤3: 导出并压缩镜像
print_step "步骤 3/8: 导出并压缩镜像"
IMAGE_TAR="$TEMP_DIR/chatwoot-production.tar"
IMAGE_GZ="$TEMP_DIR/chatwoot-production.tar.gz"

# 清理旧文件
rm -f $IMAGE_TAR $IMAGE_GZ

print_warning "正在导出镜像... (这可能需要几分钟)"
docker save $IMAGE_NAME -o $IMAGE_TAR
print_success "镜像导出完成"

print_warning "正在压缩镜像..."
gzip -c $IMAGE_TAR > $IMAGE_GZ
ORIGINAL_SIZE=$(du -h $IMAGE_TAR | cut -f1)
COMPRESSED_SIZE=$(du -h $IMAGE_GZ | cut -f1)
print_success "压缩完成: $ORIGINAL_SIZE -> $COMPRESSED_SIZE"

# 步骤4: 测试SSH连接
print_step "步骤 4/8: 测试SSH连接"
if ssh $REMOTE_USER@$REMOTE_SERVER "echo 'SSH连接成功'" > /dev/null 2>&1; then
    print_success "SSH连接正常"
else
    print_error "无法连接到远程服务器，请检查SSH配置"
    exit 1
fi

# 步骤5: 传输文件到远程服务器
print_step "步骤 5/8: 传输文件到远程服务器"

# 创建远程目录
ssh $REMOTE_USER@$REMOTE_SERVER "mkdir -p $REMOTE_DIR"

# 传输配置文件
print_warning "传输配置文件..."
scp $LOCAL_DIR/docker-compose.production.yaml $LOCAL_DIR/.env $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/
print_success "配置文件传输完成"

# 传输镜像
print_warning "传输Docker镜像 ($COMPRESSED_SIZE)... (这可能需要几分钟)"
if scp $IMAGE_GZ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/; then
    print_success "镜像传输完成"
else
    print_error "镜像传输失败"
    exit 1
fi

# 步骤6: 在远程服务器上解压并导入镜像
print_step "步骤 6/8: 在远程服务器上部署"

ssh $REMOTE_USER@$REMOTE_SERVER << 'ENDSSH'
set -e
cd /root/chatwoot

echo "解压镜像..."
rm -f chatwoot-production.tar
gunzip -f chatwoot-production.tar.gz

echo "导入Docker镜像..."
docker load -i chatwoot-production.tar

echo "停止现有容器..."
docker-compose -f docker-compose.production.yaml down 2>/dev/null || true

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

# 步骤7: 检查服务健康状态
print_step "步骤 7/8: 检查服务健康状态"
sleep 5
if ssh $REMOTE_USER@$REMOTE_SERVER "curl -s http://localhost:8080 | grep -q 'Chatwoot'"; then
    print_success "服务运行正常"
else
    print_warning "服务可能还在启动中，请稍后检查"
fi

# 步骤8: 清理本地临时文件
print_step "步骤 8/8: 清理临时文件"
rm -f $IMAGE_TAR $IMAGE_GZ
print_success "临时文件清理完成"

# 部署完成
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 部署成功！${NC}"
echo "=========================================="
echo ""
echo "访问地址: http://$REMOTE_SERVER:8080"
echo "登录邮箱: admin@example.com"
echo "登录密码: Chatwoot123!"
echo ""
echo "查看日志: ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose -f docker-compose.production.yaml logs -f'"
echo "重启服务: ssh $REMOTE_USER@$REMOTE_SERVER 'cd $REMOTE_DIR && docker-compose -f docker-compose.production.yaml restart'"
echo ""
