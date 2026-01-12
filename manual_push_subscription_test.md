# 推送订阅注册测试 - 手动步骤

## 方法1: 使用现有的 pubsub_token 直接注册

根据数据库查询,contact 27 (yushuangqi@hotmail.com) 的 contact_inbox 30 的 pubsub_token 是: `rN6zrwhBsyYpWqhG7e2QWh3W`

### 步骤1: 先删除旧的订阅(可选)

```bash
docker-compose exec postgres psql -U postgres -d chatwoot -c "DELETE FROM contact_push_subscriptions WHERE push_token = 'fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ';"
```

### 步骤2: 直接在数据库中插入订阅记录

```bash
docker-compose exec postgres psql -U postgres -d chatwoot -c "
INSERT INTO contact_push_subscriptions (contact_id, contact_inbox_id, push_token, device_id, platform, created_at, updated_at)
VALUES (
  27,
  30,
  'fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ',
  'manual_test_' || EXTRACT(EPOCH FROM NOW())::TEXT,
  'android',
  NOW(),
  NOW()
)
RETURNING id, contact_id, contact_inbox_id, device_id;
"
```

### 步骤3: 验证订阅是否创建成功

```bash
docker-compose exec postgres psql -U postgres -d chatwoot -c "
SELECT id, contact_id, contact_inbox_id, device_id, LEFT(push_token, 30) as token_preview, created_at
FROM contact_push_subscriptions
WHERE contact_id = 27
ORDER BY created_at DESC;
"
```

### 步骤4: 测试推送

发送一条测试消息到会话 14,验证是否能收到推送。

## 方法2: 通过 Rails Console 注册

```ruby
# 进入 Rails console
docker-compose exec rails sh -c "cd /app && bundle exec rails console"

# 在 console 中执行
contact_inbox = ContactInbox.find(30)
subscription = ContactPushSubscription.create!(
  contact: contact_inbox.contact,
  contact_inbox: contact_inbox,
  push_token: 'fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ',
  device_id: "manual_test_#{Time.now.to_i}",
  platform: 'android'
)

puts "订阅创建成功!"
puts "ID: #{subscription.id}"
puts "Contact ID: #{subscription.contact_id}"
puts "Contact Inbox ID: #{subscription.contact_inbox_id}"
```

## 关键信息

- **Contact ID**: 27
- **Contact Inbox ID**: 30
- **Identifier**: yushuangqi@hotmail.com
- **Pubsub Token**: rN6zrwhBsyYpWqhG7e2QWh3W
- **Source ID**: 583dec01-fac3-40c4-ad35-d0a06cd746e1
- **FCM Token**: fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ
