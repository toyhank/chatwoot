#!/bin/bash

#############################################
# Chatwoot 生产镜像构建脚本
# 用途: 本地构建生产镜像并可选导出
#############################################

set -e

# 配置
IMAGE_NAME="chatwoot/chatwoot:production"
APP_VERSION=$(cat /home/chatwoot1/chatwoot/config/app.yml | grep "version:" | head -1 | awk '{print $2}' | tr -d '"' || echo "latest")

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}===> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo "=========================================="
echo "  Chatwoot 生产镜像构建工具"
echo "=========================================="
echo ""

# 步骤1: 清理旧构建
print_step "步骤 1/4: 清理旧构建缓存"
cd /home/chatwoot1/chatwoot

# 可选：清理 node_modules 和 tmp（可节省空间）
# rm -rf node_modules tmp/cache

print_success "清理完成"

# 步骤2: 构建镜像
print_step "步骤 2/4: 构建 Docker 镜像"
print_warning "这可能需要 10-20 分钟，请耐心等待..."

# 构建镜像
if docker build -f docker/Dockerfile \
  -t $IMAGE_NAME \
  -t chatwoot/chatwoot:v$APP_VERSION \
  -t chatwoot/chatwoot:latest \
  --network=host \
  .; then
  print_success "镜像构建成功！"
else
  print_error "镜像构建失败"
  exit 1
fi

# 步骤3: 显示镜像信息
print_step "步骤 3/4: 镜像信息"
docker images | grep chatwoot/chatwoot | head -3

# 步骤4: 询问是否导出
print_step "步骤 4/4: 导出选项"
echo ""
echo "是否要导出镜像？"
echo "1) 是 - 导出为 .tar.gz（用于传输到其他服务器）"
echo "2) 否 - 仅构建镜像"
echo ""
read -p "请选择 [1/2]: " choice

if [ "$choice" = "1" ]; then
  print_warning "正在导出镜像..."
  
  OUTPUT_DIR="/tmp"
  OUTPUT_FILE="$OUTPUT_DIR/chatwoot-production-$(date +%Y%m%d-%H%M%S).tar.gz"
  
  # 导出并压缩
  docker save $IMAGE_NAME | gzip > $OUTPUT_FILE
  
  SIZE=$(du -h $OUTPUT_FILE | cut -f1)
  print_success "镜像已导出到: $OUTPUT_FILE"
  print_success "文件大小: $SIZE"
  
  echo ""
  echo "使用方法："
  echo "1. 传输到远程服务器: scp $OUTPUT_FILE user@server:/path/"
  echo "2. 在远程服务器加载: docker load < /path/$(basename $OUTPUT_FILE)"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 构建完成！${NC}"
echo "=========================================="
echo ""
echo "镜像标签："
echo "  - $IMAGE_NAME"
echo "  - chatwoot/chatwoot:v$APP_VERSION"
echo "  - chatwoot/chatwoot:latest"
echo ""
echo "使用方法："
echo "  docker run -d -p 3000:3000 $IMAGE_NAME"
echo ""

