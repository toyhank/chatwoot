#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
# 建议注释掉下面这一行，保留缓存可以让构建更快
# rm -rf /app/tmp/cache/*

# 2. 正常安装依赖
# pnpm 会自动检查 node_modules，如果包都在，这步会在 1 秒内完成
pnpm install

echo "Ready to run Vite development server."

exec "$@"
