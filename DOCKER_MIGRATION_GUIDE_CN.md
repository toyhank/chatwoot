# Docker 中运行数据库迁移指南

## 方法 1: 使用 docker-compose exec（推荐）

适用于容器已经在运行的情况：

```bash
# 在运行中的 rails 容器中执行迁移
docker-compose exec rails bundle exec rails db:migrate

# 如果使用 docker-compose.local.yml
docker-compose -f docker-compose.local.yml exec rails bundle exec rails db:migrate

# 如果使用 docker-compose.development.yaml
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails db:migrate
```

## 方法 2: 使用 docker-compose run（临时容器）

适用于容器未运行，或需要一次性执行迁移：

```bash
# 创建临时容器执行迁移
docker-compose run --rm rails bundle exec rails db:migrate

# 指定环境变量
docker-compose run --rm -e RAILS_ENV=production rails bundle exec rails db:migrate
```

## 方法 3: 直接使用 docker exec

如果知道容器名称或 ID：

```bash
# 查看运行中的容器
docker ps

# 在指定容器中执行迁移
docker exec -it <container_name_or_id> bundle exec rails db:migrate

# 例如：
docker exec -it chatwoot_rails_1 bundle exec rails db:migrate
```

## 方法 4: 生产环境（docker-compose.yaml）

对于生产环境，通常需要设置超时时间：

```bash
docker-compose exec rails bash -c "POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:migrate"
```

或者使用 Chatwoot 的自定义任务：

```bash
docker-compose exec rails bundle exec rails db:chatwoot_prepare
```

## 其他有用的数据库命令

```bash
# 查看迁移状态
docker-compose exec rails bundle exec rails db:migrate:status

# 回滚最后一次迁移
docker-compose exec rails bundle exec rails db:rollback

# 回滚指定步数
docker-compose exec rails bundle exec rails db:rollback STEP=3

# 重置数据库（开发环境）
docker-compose exec rails bundle exec rails db:reset

# 创建数据库（如果不存在）
docker-compose exec rails bundle exec rails db:create

# 加载种子数据
docker-compose exec rails bundle exec rails db:seed

# 进入 Rails 控制台
docker-compose exec rails bundle exec rails console
```

## 注意事项

1. **确保数据库连接正常**: 迁移前确保 postgres 容器正在运行
   ```bash
   docker-compose ps postgres
   ```

2. **环境变量**: 确保 `.env` 或 `.env.develop` 文件配置了正确的数据库连接信息

3. **备份**: 生产环境执行迁移前建议备份数据库

4. **查看日志**: 如果迁移失败，可以查看容器日志
   ```bash
   docker-compose logs rails
   ```

## 示例：执行我们刚创建的迁移

```bash
# 在开发环境中
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails db:migrate

# 或者使用 run 命令
docker-compose -f docker-compose.development.yaml run --rm rails bundle exec rails db:migrate
```

迁移成功后，`email_verification_codes` 表将被创建。
