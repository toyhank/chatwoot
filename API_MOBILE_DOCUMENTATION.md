# Chatwoot Mobile API 开发文档

本文档详细说明了 Chatwoot 移动端所需的认证、签到及余额查询接口。

---

## 🔑 基础配置
- **Base URL**: `http://YOUR_SERVER_IP:8080` (如果是 Android 模拟器，请使用 `http://10.0.2.2:8080`)
- **Content-Type**: `application/json`

---

## 1. 用户登录 (Login)
用户通过邮箱和密码登录，并获取 `access_token`。

- **接口地址**: `POST /api/mobile/register/login`
- **请求参数**:
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

- **响应成功 (200 OK)**:
```json
{
  "status": 200,
  "msg": "登录成功",
  "data": {
    "uid": 123,
    "email": "user@example.com",
    "nickname": "张三",
    "avatar": "http://domain.com/avatar.png",
    "access_token": "eyJhbGciOiJIUzI1NiJ...",
    "balance": 100, // 初始余额
    "message": "登录成功"
  }
}
```

---

## 2. 获取个人信息 / 刷新余额 (Profile / Refresh Balance)
用于在个人中心手动刷新或定时同步用户最新的资产状态。

- **接口地址**: `GET /api/mobile/user/profile`
- **请求头 (Header)**:
  `Authorization: Bearer <ACCESS_TOKEN>`

- **响应成功 (200 OK)**:
```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 123,
    "email": "user@example.com",
    "name": "张三",
    "balance": 105 // 最新余额
  }
}
```

---

## 3. 每日签到 (Daily Check-in)
执行每日签到逻辑，成功后余额自动加 5。

- **接口地址**: `POST /api/mobile/user/check_in`
- **请求头 (Header)**:
  `Authorization: Bearer <ACCESS_TOKEN>`

- **响应成功 (200 OK)**:
```json
{
  "status": 200,
  "msg": "签到成功，余额已增加",
  "data": {
    "balance": 110
  }
}
```

- **失败示例 (422 Unprocessable Entity - 重复签到)**:
```json
{
  "status": 422,
  "msg": "今天已经签到过了",
  "data": {
    "balance": 110
  }
}
```

---

## 4. 账号删除 (Delete Account)
注销当前用户账号及其关联数据。

- **接口地址**: `DELETE /api/mobile/user/delete`
- **请求头 (Header)**:
  `Authorization: Bearer <ACCESS_TOKEN>`

- **响应成功 (200 OK)**:
```json
{
  "status": 200,
  "msg": "账户删除成功",
  "data": null
}
```

---

## ⚠️ 错误码总结 (Status Codes)

| Status | 说明 |
| :--- | :--- |
| **200** | 请求成功 |
| **400** | 业务逻辑错 (如密码错误) |
| **401** | 未授权 (Token 无效或过期) |
| **422** | 语义错误 (如重复签到) |
| **500** | 服务器内部错误 |
