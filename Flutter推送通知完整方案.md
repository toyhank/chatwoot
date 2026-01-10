# Flutter 应用 Chatwoot 推送通知实现指南

## 📋 概述

本文档详细说明如何在 Flutter 应用中实现 Chatwoot 服务器的推送通知功能。

## 🏗️ 系统架构

```mermaid
sequenceDiagram
    participant Customer as 客户(Flutter App)
    participant FCM as Firebase Cloud Messaging
    participant Server as Chatwoot Server
    participant Agent as 客服

    Agent->>Server: 发送消息
    Server->>Server: 生成推送通知
    Server->>FCM: 发送 FCM 通知
    FCM-->>Customer: 推送通知
    Customer->>Customer: 显示通知
    Customer->>Server: 点击通知打开对话
```

## 📦 依赖包

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
  http: ^1.2.0
```

## 🔧 实现代码

### 1. 推送通知服务类

创建 `lib/services/push_notification_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 后台消息处理器（必须是顶级函数）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('处理后台消息: ${message.messageId}');
  // 可以在这里处理后台通知
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;

  /// 初始化推送通知服务
  static Future<void> initialize() async {
    // 1. 请求通知权限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('用户授权状态: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('用户已授予通知权限');
    } else {
      print('用户拒绝通知权限');
      return;
    }

    // 2. 初始化本地通知
    await _initializeLocalNotifications();

    // 3. 获取 FCM Token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // 4. 监听 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token 刷新: $newToken');
      _fcmToken = newToken;
      // 重新注册到服务器
      registerDeviceToken(newToken);
    });

    // 5. 设置后台消息处理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. 前台消息处理
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. 通知点击处理
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. 检查是否从通知启动
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// 初始化本地通知
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建 Android 通知渠道
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chatwoot_channel',
      '客服消息',
      description: '接收客服的回复消息',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 处理前台消息
  static void _handleForegroundMessage(RemoteMessage message) {
    print('收到前台消息: ${message.messageId}');
    print('标题: ${message.notification?.title}');
    print('内容: ${message.notification?.body}');
    print('数据: ${message.data}');

    // 显示本地通知
    _showLocalNotification(message);
  }

  /// 显示本地通知
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // 解析 Chatwoot 数据
    final data = message.data;
    String? payloadJson = data['payload'];
    Map<String, dynamic>? chatwootData;

    if (payloadJson != null) {
      try {
        final payload = json.decode(payloadJson);
        chatwootData = payload['data']?['notification'];
      } catch (e) {
        print('解析 payload 错误: $e');
      }
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chatwoot_channel',
      '客服消息',
      channelDescription: '接收客服的回复消息',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '新消息',
      message.notification?.body ?? '',
      notificationDetails,
      payload: json.encode(chatwootData ?? message.data),
    );
  }

  /// 处理通知点击
  static void _handleNotificationTap(RemoteMessage message) {
    print('用户点击了通知: ${message.messageId}');

    // 解析数据并导航
    final data = message.data;
    print('通知数据: $data');

    // 这里可以根据数据导航到相应的对话页面
    // 例如：获取 conversation_id 并打开对话
    if (data.containsKey('payload')) {
      try {
        final payload = json.decode(data['payload']);
        final notificationData = payload['data']?['notification'];
        final conversationId = notificationData?['conversation_id'];

        if (conversationId != null) {
          // 导航到对话页面
          print('打开对话 ID: $conversationId');
          // Navigator.push(context, MaterialPageRoute(...));
        }
      } catch (e) {
        print('解析通知数据错误: $e');
      }
    }
  }

  /// 本地通知点击回调
  static void _onNotificationTapped(NotificationResponse response) {
    print('点击了本地通知');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      print('通知数据: $data');

      // 处理导航逻辑
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        print('打开对话 ID: $conversationId');
        // 实现导航逻辑
      }
    }
  }

  /// 获取当前 FCM Token
  static String? get fcmToken => _fcmToken;

  /// 注册设备 Token 到 Chatwoot 服务器
  static Future<bool> registerDeviceToken(String? token) async {
    if (token == null) {
      print('Token 为空，无法注册');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('YOUR_CHATWOOT_SERVER/api/v1/notification_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'api_access_token': 'YOUR_USER_API_TOKEN', // 需要用户的 API token
        },
        body: json.encode({
          'subscription_type': 'fcm',
          'subscription_attributes': {
            'push_token': token,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('设备 Token 注册成功');
        return true;
      } else {
        print('设备 Token 注册失败: ${response.statusCode}');
        print('响应: ${response.body}');
        return false;
      }
    } catch (e) {
      print('注册设备 Token 错误: $e');
      return false;
    }
  }
}
```

### 2. 主应用入口

修改 `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp();

  // 初始化推送通知服务
  await PushNotificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatwoot Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
  }

  void _loadFcmToken() {
    setState(() {
      _fcmToken = PushNotificationService.fcmToken;
    });
  }

  Future<void> _registerToken() async {
    final success = await PushNotificationService.registerDeviceToken(_fcmToken);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '设备注册成功' : '设备注册失败'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatwoot 客户端'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FCM Token:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _fcmToken ?? '获取中...',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fcmToken != null ? _registerToken : null,
              child: Text('注册设备到服务器'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔐 服务器端配置

### 配置 Firebase 凭据

在 Chatwoot 服务器的 `.env` 文件中添加：

```bash
# Firebase 项目 ID
FIREBASE_PROJECT_ID=your-firebase-project-id

# Firebase 服务账号凭据（完整的 JSON 内容）
FIREBASE_CREDENTIALS='{"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}'
```

### API 端点

您的 Chatwoot 服务器提供以下 API 用于注册 FCM Token:

**端点**: `POST /api/v1/notification_subscriptions`

**请求头**:

```
Content-Type: application/json
api_access_token: <用户的 API Token>
```

**请求体**:

```json
{
  "subscription_type": "fcm",
  "subscription_attributes": {
    "push_token": "<FCM Device Token>"
  }
}
```

## 📱 数据结构

### Chatwoot 推送通知数据格式

当客服发送消息时，Chatwoot 服务器会发送以下格式的推送通知：

```json
{
  "notification": {
    "title": "新消息来自客服",
    "body": "消息内容..."
  },
  "data": {
    "payload": "{\"data\":{\"notification\":{\"id\":123,\"notification_type\":\"conversation_creation\",\"primary_actor_type\":\"User\",\"primary_actor_id\":10,\"primary_actor\":{\"id\":10,\"name\":\"客服名称\",\"availability_status\":\"online\",\"type\":\"user\"},\"conversation_id\":456,\"account_id\":1}}}"
  },
  "android": {
    "priority": "high"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default"
      }
    }
  }
}
```

## ✅ 测试推送通知

### 1. 获取 FCM Token

运行 Flutter 应用后，从界面复制 FCM Token。

### 2. 使用 Chatwoot API 注册设备

```bash
curl -X POST 'https://your-chatwoot-server.com/api/v1/notification_subscriptions' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: YOUR_API_TOKEN' \
  -d '{
    "subscription_type": "fcm",
    "subscription_attributes": {
      "push_token": "YOUR_FCM_TOKEN"
    }
  }'
```

### 3. 发送测试消息

让客服在 Chatwoot 后台发送一条消息，您的 Flutter 应用应该会收到推送通知。

## 🎯 最佳实践

1. **权限处理**: 在适当的时机请求通知权限，不要在应用启动时立即请求
2. **Token 管理**: 定期检查并更新 FCM Token
3. **错误处理**: 妥善处理网络错误和 Token 过期情况
4. **通知分组**: 对于同一对话的多条消息，可以考虑通知分组
5. **离线处理**: 确保应用在后台和关闭状态下都能接收通知

## 🔍 调试技巧

1. 查看 Firebase Console 的消息日志
2. 使用 `adb logcat` 查看 Android 日志
3. 在 Chatwoot 服务器日志中查看推送发送记录：
   ```bash
   tail -f log/production.log | grep "FCM push"
   ```

## 📚 相关文件

- Chatwoot 推送服务: [push_notification_service.rb](file:///home/chatwoot1/chatwoot/app/services/notification/push_notification_service.rb)
- Chatwoot 通知订阅模型: [notification_subscription.rb](file:///home/chatwoot1/chatwoot/app/models/notification_subscription.rb)
- Firebase 配置: [installation_config.yml](file:///home/chatwoot1/chatwoot/config/installation_config.yml#L308-L320)

## 🚨 常见问题

### Q: 收不到推送通知？

- 检查 Firebase 配置是否正确
- 确认设备 Token 已成功注册到服务器
- 检查用户的通知设置是否开启
- 查看服务器日志是否有错误

### Q: 后台收不到通知？

- 确保 AndroidManifest.xml 配置正确
- 检查设备的电池优化设置
- 确保后台消息处理器已正确配置

### Q: 如何自定义通知样式？

- 修改 `AndroidNotificationDetails` 参数
- 可以添加自定义图标、声音、振动模式等
