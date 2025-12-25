#!/bin/bash
# 快速配置向导

echo "╔═══════════════════════════════════════════════════╗"
echo "║   Chatwoot 多环境配置向导                         ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# 检测当前环境
if [ -f /proc/sys/kernel/osrelease ] && grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo "🔍 检测到 WSL 环境"
    DETECTED_ENV="local"
elif ip addr | grep -q "172."; then
    echo "🔍 检测到 Docker 网络环境"
    DETECTED_ENV="server"
else
    echo "🔍 检测到本地环境"
    DETECTED_ENV="local"
fi

echo ""
echo "请选择您要配置的环境："
echo "1) 本地开发环境（localhost）"
echo "2) 服务器生产环境（需要配置IP/域名）"
echo ""
read -p "请输入选项 [1/2]: " choice

case $choice in
    1)
        echo ""
        echo "✅ 已选择：本地开发环境"
        echo "📝 FRONTEND_URL 将设置为: http://localhost:3000"
        echo ""
        read -p "按回车键继续，或 Ctrl+C 取消..."
        cp .env.local .env
        echo "✅ 配置完成！"
        echo ""
        echo "🚀 启动命令:"
        echo "   ./start-local.sh"
        echo ""
        echo "🌐 访问地址:"
        echo "   http://localhost:8080"
        ;;
    2)
        echo ""
        echo "✅ 已选择：服务器生产环境"
        echo ""
        echo "请输入您的服务器访问地址："
        echo ""
        echo "示例："
        echo "  - 使用域名（推荐）: https://chatwoot.example.com"
        echo "  - 使用IP地址: http://192.168.1.100:8080"
        echo "  - 使用公网IP: http://123.456.789.10:8080"
        echo ""
        read -p "请输入 FRONTEND_URL: " frontend_url
        
        if [ -z "$frontend_url" ]; then
            echo "❌ 错误：FRONTEND_URL 不能为空"
            exit 1
        fi
        
        # 更新配置文件
        sed -i "s|FRONTEND_URL=http://YOUR_SERVER_IP:8080|FRONTEND_URL=$frontend_url|g" .env.production.local
        cp .env.production.local .env
        
        echo ""
        echo "✅ 配置完成！"
        echo "📝 FRONTEND_URL 已设置为: $frontend_url"
        echo ""
        echo "🚀 启动命令:"
        echo "   ./start-server.sh"
        echo ""
        echo "🌐 访问地址:"
        echo "   $frontend_url"
        
        # 如果使用 http，提示安全警告
        if [[ $frontend_url == http://* ]]; then
            echo ""
            echo "⚠️  安全提示: 您正在使用 HTTP 协议"
            echo "   生产环境建议使用 HTTPS 保护数据安全"
        fi
        ;;
    *)
        echo "❌ 无效的选项"
        exit 1
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════"
echo "📚 查看完整文档: cat DEPLOYMENT_GUIDE.md"
echo "═══════════════════════════════════════════════════"

