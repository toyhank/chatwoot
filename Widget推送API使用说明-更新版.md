# Widget Push Subscriptions API 使用说明

## ❌ 问题：404 错误

如果您访问 `http://127.0.0.1:8080/api/v1/widget/push_subscriptions` 得到 404 错误，这是因为 **Widget API 需要特殊的认证机制**。

## 🔐 认证要求

Widget API 需要两个认证参数：

### 1. **website_token** (必需)

- 在 Chatwoot 后台创建 Website Channel 时生成
- 用于标识是哪个 Widget/Inbox
- 在请求参数中传递

### 2. **X-Auth-Token** (必需)

- Contact 的认证令牌
- 首次创建 contact 时由服务器生成
- 在请求头中传递

## 📍 正确的 API 调用方式

### 第一步：创建 Contact 并获取 Auth Token

首先需要通过 Widget API 创建或获取一个 contact，这会返回 `X-Auth-Token`：

```http
POST /api/v1/widget/contacts
Content-Type: application/json

{
  "website_token": "YOUR_WEBSITE_TOKEN",
  "contact": {
    "email": "user@example.com",
    "name": "Test User"
  }
}
```

**响应示例**：

```json
{
  "id": 123,
  "name": "Test User",
  "email": "user@example.com",
  "pubsub_token": "abc123...",
  "source_id": "contact_source_id"
}
```

同时，响应头会包含 `X-Auth-Token`，需要保存这个 token。

### 第二步：注册推送订阅

使用获取的 `X-Auth-Token` 来注册推送：

```http
POST /api/v1/widget/push_subscriptions
Content-Type: application/json
X-Auth-Token: YOUR_CONTACT_AUTH_TOKEN

{
  "website_token": "YOUR_WEBSITE_TOKEN",
  "push_subscription": {
    "push_token": "FCM_DEVICE_TOKEN",
    "device_id": "unique-device-id",
    "platform": "android"
  }
}
```

## 🧪 测试步骤

### 1. 获取 Website Token

在 Chatwoot 后台：

1. 进入 Settings → Inboxes
2. 选择或创建一个 Website Channel
3. 在 Configuration → Widget 页面找到 `Website Token`

### 2. 使用 cURL 测试

```bash
# 第一步：创建 contact 并获取 auth token
curl -X POST http://127.0.0.1:8080/api/v1/widget/contacts \
  -H "Content-Type: application/json" \
  -v \
  -d '{
    "website_token": "YOUR_WEBSITE_TOKEN",
    "contact": {
      "email": "test@example.com",
      "name": "Test User"
    }
  }'

# 从响应头复制 X-Auth-Token 值

# 第二步：注册推送（使用上一步获取的 X-Auth-Token）
curl -X POST http://127.0.0.1:8080/api/v1/widget/push_subscriptions \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: COPIED_AUTH_TOKEN_HERE" \
  -d '{
    "website_token": "YOUR_WEBSITE_TOKEN",
    "push_subscription": {
      "push_token": "test_fcm_token_12345",
      "device_id": "test_device_001",
      "platform": "android"
    }
  }'
```

### 3. 检查数据库

成功后可以在数据库中验证：

```bash
docker-compose -f docker-compose.development.yaml exec postgres \
  psql -U postgres -d chatwoot \
  -c "SELECT id, push_token, device_id, platform, created_at FROM contact_push_subscriptions;"
```

## 📱 Flutter 实现

### 完整的认证流程代码

```dart
class ChatwootService {
  final String baseUrl;
  final String websiteToken;
  String? _authToken; // 保存认证 token

  ChatwootService({
    required this.baseUrl,
    required this.websiteToken,
  });

  /// 步骤1: 初始化 Widget 并获取 contact
  ///
  /// ⭐ 重要：传递 email 参数可以让 Chatwoot 自动合并相同邮箱的 Contacts
  /// 这样无论在哪个设备登录，都会使用同一个会话和推送订阅
  Future<bool> initializeWidget({String? email, String? name}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/widget/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'website_token': websiteToken,
        }),
      );

      if (response.statusCode == 200) {
        // 从响应 JSON 获取 auth token
        final data = json.decode(response.body);
        _authToken = data['website_channel_config']['auth_token'];

        // 如果提供了 email，更新 contact 信息以启用自动合并
        if (email != null) {
          await updateContact(email: email, name: name);
        }

        // 保存到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('chatwoot_auth_token', _authToken!);

        print('✅ Widget 初始化成功');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Widget 初始化失败: $e');
      return false;
    }
  }

  /// 更新 Contact 信息（用于启用 email 合并）
  Future<bool> updateContact({String? email, String? name}) async {
    if (_authToken == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/widget/contact'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': _authToken!,
        },
        body: json.encode({
          'website_token': websiteToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ 更新 Contact 失败: $e');
      return false;
    }
  }

  /// 步骤2: 注册推送订阅
  Future<bool> registerPushToken(String fcmToken, String deviceId) async {
    // 确保已有 auth token
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('chatwoot_auth_token');

      if (_authToken == null) {
        print('❌ 缺少 auth token，请先初始化 contact');
        return false;
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': _authToken!,
        },
        body: json.encode({
          'website_token': websiteToken,
          'push_subscription': {
            'push_token': fcmToken,
            'device_id': deviceId,
            'platform': 'android',
          }
        }),
      );

      if (response.statusCode == 201) {
        print('✅ 推送 Token 注册成功');
        return true;
      } else {
        print('❌ 注册失败: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 注册错误: $e');
      return false;
    }
  }

  /// 取消推送订阅
  Future<bool> unregisterPushToken(String fcmToken) async {
    if (_authToken == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/widget/push_subscriptions/$fcmToken'),
        headers: {
          'X-Auth-Token': _authToken!,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ 取消订阅错误: $e');
      return false;
    }
  }
}
```

### 使用示例

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 初始化 Chatwoot 服务
  final chatwoot = ChatwootService(
    baseUrl: 'http://127.0.0.1:8080',
    websiteToken: 'YOUR_WEBSITE_TOKEN', // 从后台获取
  );

  // 第一步：初始化 contact
  await chatwoot.initializeContact(
    email: 'user@example.com',
    name: 'Test User',
  );

  // 第二步：初始化推送
  await PushNotificationService.initialize();

  // 第三步：获取 FCM token 并注册
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    await chatwoot.registerPushToken(
      fcmToken,
      'device_001', // 唯一设备 ID
    );
  }

  runApp(MyApp());
}
```

## 🔍 常见问题

### Q1: 为什么会得到 404 错误？

**A**: Widget API 需要认证。没有传递 `website_token` 或 `X-Auth-Token` 会导致请求被拒绝。

### Q2: 如何获取 website_token？

**A**:

1. 登录 Chatwoot 后台
2. Settings → Inboxes → 选择 Website Channel
3. 在 Configuration 页面查看 Widget Token

### Q3: 如何获取 X-Auth-Token？

**A**:

1. 首次创建 contact 时，服务器会在响应头返回
2. 需要保存这个 token 用于后续 API 调用
3. 可以存储在 SharedPreferences 中

### Q4: Contact 是什么？

**A**: Contact 代表使用 Widget 的客户。每个客户都有唯一的 `source_id` 和 `auth_token`。

### Q5: 可以跳过 Contact 创建直接注册推送吗？

**A**: 不可以。Widget API 的设计要求先创建 contact，因为推送订阅需要关联到具体的 contact 和 contact_inbox。

## 📊 API 路由验证

确认路由已正确配置：

```bash
docker-compose -f docker-compose.development.yaml exec rails \
  bundle exec rails routes | grep push_subscription
```

应该看到：

```
api_v1_widget_push_subscriptions POST   /api/v1/widget/push_subscriptions
api_v1_widget_push_subscription  DELETE  /api/v1/widget/push_subscriptions/:id
```

## ✅ 完整测试流程

```bash
# 1. 设置变量
WEBSITE_TOKEN="your_website_token_here"
BASE_URL="http://127.0.0.1:8080"

# 2. 创建 contact
RESPONSE=$(curl -i -X POST "$BASE_URL/api/v1/widget/contacts" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"contact\": {
      \"email\": \"test@example.com\",
      \"name\": \"Test User\"
    }
  }")

# 3. 提取 X-Auth-Token
AUTH_TOKEN=$(echo "$RESPONSE" | grep -i "x-auth-token" | awk '{print $2}' | tr -d '\r')

echo "Auth Token: $AUTH_TOKEN"

# 4. 注册推送
curl -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"push_subscription\": {
      \"push_token\": \"test_fcm_token_123\",
      \"device_id\": \"test_device_001\",
      \"platform\": \"android\"
    }
  }"
```

## 📚 相关文件

- [push_subscriptions_controller.rb](file:///home/chatwoot1/chatwoot/app/controllers/api/v1/widget/push_subscriptions_controller.rb) - 控制器代码
- [base_controller.rb](file:///home/chatwoot1/chatwoot/app/controllers/api/v1/widget/base_controller.rb) - 基础控制器（含认证逻辑）
- [website_token_helper.rb](file:///home/chatwoot1/chatwoot/app/controllers/concerns/website_token_helper.rb) - 认证 helper
- [routes.rb:408](file:///home/chatwoot1/chatwoot/config/routes.rb#L408) - 路由配置
