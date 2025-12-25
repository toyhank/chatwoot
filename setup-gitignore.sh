#!/bin/bash
# 安全配置脚本 - 将敏感配置添加到 .gitignore

echo "🔒 配置 Git 忽略敏感文件..."

# 备份 .gitignore
if [ -f .gitignore ]; then
    cp .gitignore .gitignore.backup
    echo "✅ 已备份 .gitignore 到 .gitignore.backup"
fi

# 添加环境配置文件到 .gitignore
cat >> .gitignore << 'EOF'

# 多环境配置文件（包含敏感信息）
.env.local
.env.production.local
.env.backup

# 启动脚本日志
*.log
EOF

echo "✅ 已将以下文件添加到 .gitignore："
echo "   - .env.local"
echo "   - .env.production.local"
echo "   - .env.backup"
echo ""
echo "💡 这些文件包含敏感配置信息，不应提交到 Git 仓库"

