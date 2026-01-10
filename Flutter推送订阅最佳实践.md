# Flutter 推送订阅最佳实践

## 问题总结

在多用户切换场景下，会遇到以下问题：
1. **Token 冲突**：同一设备的 FCM Token 被旧用户占用
2. **删除失败**：切换用户后，用新用户的 auth token 无法删除旧用户的订阅（返回 404）
3. **注册失败**：因为 Token 已被占用，新用户无法注册（返回 422）

## 根本原因

Chatwoot 的订阅删除 API 原本只能删除**当前用户**的订阅。当用户切换后：
- 新用户的 auth token 变了
- 用新 token 查找旧用户的订阅，找不到 → 404
- 旧订阅还在数据库中 → 注册时报 Token 已占用

## ✅ 服务器端改进（已完成）

已修改 `/app/controllers/api/v1/widget/push_subscriptions_controller.rb`：

```ruby
def destroy
  # 支持按 device_id 删除（推荐）
  if push_subscription_params[:device_id].present?
    subscription = ContactPushSubscription.find_by(
      device_id: push_subscription_params[:device_id]
    )
  elsif params[:push_token].present?
    # 向后兼容
    subscription = ContactPushSubscription.find_by(
      contact_inbox: @contact_inbox,
      push_token: params[:push_token]
    )
  end
  
  if subscription
    subscription.destroy
    head :ok
  else
    head :not_found
  end
end
```

**改进点**：
- ✅ 支持按 `device_id` 删除
- ✅ 即使用户切换了，也能删除同一设备的旧订阅
- ✅ 保持向后兼容

## 🔧 Flutter 端改进

### 1. 更新删除方法

**当前代码（有问题）**：
```dart
// ❌ 没有传递 device_id
Future<void> deletePushSubscription() async {
  final token = await FirebaseMessaging.instance.getToken();
  final response = await http.delete(
    Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
    headers: {'X-Auth-Token': authToken},
  );
}
```

**改进后的代码**：
```dart
// ✅ 传递 device_id
Future<void> deletePushSubscription() async {
  final deviceId = await getDeviceId(); // 获取设备唯一标识
  
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
      headers: {
        'Content-Type': 'application/json',
        'X-Auth-Token': authToken, // 可以是任意用户的 token
      },
      body: jsonEncode({
        'push_subscription': {
          'device_id': deviceId, // ⭐ 关键：传递 device_id
        }
      }),
    );
    
    if (response.statusCode == 200) {
      print('✅ 推送订阅已删除');
    } else if (response.statusCode == 404) {
      print('ℹ️ 未找到订阅（可能已删除）');
    }
  } catch (e) {
    print('❌ 删除订阅失败: $e');
  }
}
```

### 2. 获取设备 ID 的方法

```dart
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Android ID
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown';
  }
  
  return DateTime.now().millisecondsSinceEpoch.toString();
}
```

**依赖**：
```yaml
dependencies:
  device_info_plus: ^10.0.0
```

### 3. 完整的用户切换流程

```dart
Future<void> switchUser({
  required String newEmail,
  required String newName,
}) async {
  print('🔄 检测到用户切换: $currentEmail → $newEmail');
  
  // 1. ⭐ 删除旧用户的推送订阅（使用 device_id）
  print('  - 正在删除旧用户的推送订阅...');
  await deletePushSubscription();
  
  // 2. 清除旧会话数据
  print('  - 清除旧的 auth token，准备重新初始化');
  await clearSession();
  
  // 3. 初始化新用户
  print('📝 开始初始化 Widget 获取新的 auth token...');
  await initializeWidget(
    email: newEmail,
    name: newName,
  );
  
  // 4. ⭐ 为新用户注册推送
  print('📤 正在注册推送 Token 到 Chatwoot...');
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await registerPushSubscription(token);
  }
}
```

### 4. 注册推送时也要传 device_id

```dart
Future<void> registerPushSubscription(String fcmToken) async {
  final deviceId = await getDeviceId();
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
      headers: {
        'Content-Type': 'application/json',
        'X-Auth-Token': authToken,
      },
      body: jsonEncode({
        'push_subscription': {
          'push_token': fcmToken,
          'device_id': deviceId,     // ⭐ 必须传递
          'platform': 'android',     // 或 'ios'
        }
      }),
    );
    
    if (response.statusCode == 201) {
      print('✅ 推送 Token 注册成功');
    } else {
      print('❌ 注册失败: ${response.statusCode}');
      print('  - 响应: ${response.body}');
    }
  } catch (e) {
    print('❌ 注册异常: $e');
  }
}
```

## 📋 完整示例

```dart
class ChatwootService {
  String? authToken;
  String? currentEmail;
  final String baseUrl = 'http://127.0.0.1:8080';
  
  // 获取设备 ID
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // 删除推送订阅
  Future<void> deletePushSubscription() async {
    final deviceId = await getDeviceId();
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': authToken ?? '',
        },
        body: jsonEncode({
          'push_subscription': {
            'device_id': deviceId,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ 推送订阅已删除');
      } else if (response.statusCode == 404) {
        print('ℹ️ 这是正常的（旧订阅可能已不存在）');
      } else {
        print('! 删除旧订阅失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 删除订阅异常: $e');
    }
  }
  
  // 注册推送订阅
  Future<void> registerPushSubscription(String fcmToken) async {
    final deviceId = await getDeviceId();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': authToken ?? '',
        },
        body: jsonEncode({
          'push_subscription': {
            'push_token': fcmToken,
            'device_id': deviceId,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          }
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ 推送 Token 注册成功');
      } else {
        print('❌ 注册失败: ${response.statusCode}');
        print('  - 响应: ${response.body}');
      }
    } catch (e) {
      print('❌ 注册异常: $e');
    }
  }
  
  // 切换用户
  Future<void> switchUser({
    required String newEmail,
    required String newName,
  }) async {
    if (newEmail == currentEmail) {
      print('ℹ️ 用户未变化，无需切换');
      return;
    }
    
    print('🔄 检测到用户切换: $currentEmail → $newEmail');
    
    // 1. 删除旧订阅
    print('  - 正在删除旧用户的推送订阅...');
    await deletePushSubscription();
    
    // 2. 清除会话
    print('  - 清除旧的 auth token，准备重新初始化');
    authToken = null;
    
    // 3. 初始化新用户
    print('📝 开始初始化 Widget 获取新的 auth token...');
    await initializeWidget(
      email: newEmail,
      name: newName,
    );
    
    // 4. 注册推送
    print('📤 正在注册推送 Token 到 Chatwoot...');
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await registerPushSubscription(token);
    }
    
    currentEmail = newEmail;
  }
  
  // 初始化 Widget
  Future<void> initializeWidget({
    required String email,
    required String name,
  }) async {
    // ... 您现有的初始化逻辑 ...
  }
}
```

## ✅ 检查清单

实现上述改进后，请确认：

- [ ] `getDeviceId()` 方法返回稳定的设备标识
- [ ] `deletePushSubscription()` 传递了 `device_id` 参数
- [ ] `registerPushSubscription()` 传递了 `device_id` 参数
- [ ] 用户切换时先调用 `deletePushSubscription()`
- [ ] 每次初始化后都调用 `registerPushSubscription()`

## 🧪 测试步骤

1. 用用户 A 登录并注册推送
2. 发送消息，确认收到推送 ✅
3. 切换到用户 B
4. 确认删除成功（不再返回 404）✅
5. 确认注册成功（不再返回 422）✅
6. 发送消息给用户 B，确认收到推送 ✅
7. 切换回用户 A，重复测试

## 📚 相关文件

- 服务器端修改：`/app/controllers/api/v1/widget/push_subscriptions_controller.rb`
- API 文档：`Widget推送API使用说明.md`
