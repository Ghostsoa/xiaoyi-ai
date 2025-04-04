# 通知系统API文档

## 用户接口

### 1. 获取通知状态

**请求**
- 路径: `/api/v1/notifications/status`
- 方法: `GET`

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "获取通知状态成功",
    "data": {
      "total": 10,    // 总通知数
      "unread": 5     // 未读数
    }
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "客户端ID不能为空"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "获取通知状态失败: 错误详情"
  }
  ```

### 2. 获取用户通知列表

**请求**
- 路径: `/api/v1/notifications`
- 方法: `GET`
- 参数:
  ```
  page: int [可选] - 页码，默认1
  page_size: int [可选] - 每页条数，默认20
  status: int [可选] - 通知状态（1: 未读, 2: 已读）
  type[]: int [可选] - 通知类型（可多选）
    1: 系统通知
    2: 公告
    3: 个人通知
    4: 促销活动
    5: 维护通知
  ```

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "list": [
        {
          "id": 1,
          "user_id": 1001,
          "notification_id": 1,
          "status": 1,
          "read_at": null,
          "created_at": "2023-12-01T10:00:00Z",
          "updated_at": "2023-12-01T10:00:00Z",
          "notification": {
            "id": 1,
            "title": "系统通知",
            "content": "通知内容",
            "type": 1,
            "is_global": true,
            "expired_at": null,
            "created_by": 1,
            "created_at": "2023-12-01T09:30:00Z",
            "updated_at": "2023-12-01T09:30:00Z"
          }
        }
      ],
      "total": 20
    }
  }
  ```
- 失败:
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "获取通知列表失败: 错误详情"
  }
  ```

### 3. 标记通知为已读

**请求**
- 路径: `/api/v1/notifications/read`
- 方法: `POST`
- 参数(JSON):
  ```json
  {
    "notification_ids": [1, 2, 3]  // 通知ID数组
  }
  ```

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "标记通知为已读成功"
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "参数错误: 详细信息"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "标记通知为已读失败: 错误详情"
  }
  ```

### 4. 标记所有通知为已读

**请求**
- 路径: `/api/v1/notifications/read-all`
- 方法: `POST`
- 参数: 无

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "标记所有通知为已读成功"
  }
  ```
- 失败:
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "标记所有通知为已读失败: 错误详情"
  }
  ```

## 管理员接口

### 1. 创建通知

**请求**
- 路径: `/api/v1/admin/notifications`
- 方法: `POST`
- 参数(JSON):
  ```json
  {
    "title": "通知标题",        // 必需
    "content": "通知内容",      // 必需
    "type": 1,                 // 必需，通知类型
    "is_global": true,         // 可选，是否全局通知，默认false
    "expired_at": "2023-12-31T23:59:59Z", // 可选，过期时间
    "user_ids": [1001, 1002]   // 可选，非全局通知需指定用户ID
  }
  ```

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "创建通知成功",
    "data": {
      "id": 1,
      "title": "通知标题",
      "content": "通知内容",
      "type": 1,
      "is_global": true,
      "expired_at": "2023-12-31T23:59:59Z",
      "created_by": 1,
      "created_at": "2023-12-01T09:30:00Z",
      "updated_at": "2023-12-01T09:30:00Z"
    }
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "参数错误: 详细信息"
  }
  ```
  或
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "非全局通知必须指定用户ID"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "创建通知失败: 错误详情"
  }
  ```

### 2. 更新通知

**请求**
- 路径: `/api/v1/admin/notifications/:id`
- 方法: `PUT`
- 参数(JSON):
  ```json
  {
    "title": "更新后的标题",     // 必需
    "content": "更新后的内容",   // 必需
    "type": 2,                 // 必需，通知类型
    "is_global": true,         // 可选，是否全局通知
    "expired_at": "2023-12-31T23:59:59Z" // 可选，过期时间
  }
  ```

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "更新通知成功"
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "无效的通知ID"
  }
  ```
  或
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "参数错误: 详细信息"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "更新通知失败: 错误详情"
  }
  ```

### 3. 删除通知

**请求**
- 路径: `/api/v1/admin/notifications/:id`
- 方法: `DELETE`
- 参数: 无

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "删除通知成功"
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "无效的通知ID"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "删除通知失败: 错误详情"
  }
  ```

### 4. 获取通知列表（管理员）

**请求**
- 路径: `/api/v1/admin/notifications`
- 方法: `GET`
- 参数:
  ```
  page: int [可选] - 页码，默认1
  page_size: int [可选] - 每页条数，默认20
  query: string [可选] - 搜索关键词，匹配标题和内容
  type[]: int [可选] - 通知类型（可多选）
  ```

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "list": [
        {
          "id": 1,
          "title": "系统通知",
          "content": "通知内容",
          "type": 1,
          "is_global": true,
          "expired_at": null,
          "created_by": 1,
          "created_at": "2023-12-01T09:30:00Z",
          "updated_at": "2023-12-01T09:30:00Z",
          "creator": {
            "id": 1,
            "username": "admin",
            "avatar": "头像URL"
          }
        }
      ],
      "total": 20
    }
  }
  ```
- 失败:
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "获取通知列表失败: 错误详情"
  }
  ```

### 5. 获取通知详情

**请求**
- 路径: `/api/v1/admin/notifications/:id`
- 方法: `GET`
- 参数: 无

**响应**
- 成功:
  ```json
  {
    "code": 200,
    "message": "获取通知详情成功",
    "data": {
      "id": 1,
      "title": "系统通知",
      "content": "通知内容",
      "type": 1,
      "is_global": true,
      "expired_at": null,
      "created_by": 1,
      "created_at": "2023-12-01T09:30:00Z",
      "updated_at": "2023-12-01T09:30:00Z",
      "creator": {
        "id": 1,
        "username": "admin",
        "avatar": "头像URL"
      }
    }
  }
  ```
- 失败:
  ```json
  {
    "code": 400,
    "message": "请求参数错误",
    "error": "无效的通知ID"
  }
  ```
  或
  ```json
  {
    "code": 500,
    "message": "服务器错误",
    "error": "获取通知详情失败: 错误详情"
  }
  ```

## 数据模型

### 通知类型 (NotificationType)
- `1`: 系统通知
- `2`: 公告
- `3`: 个人通知
- `4`: 促销活动
- `5`: 维护通知

### 通知状态 (NotificationStatus)
- `1`: 未读
- `2`: 已读

### 通知计数 (NotificationCount)
```json
{
  "total": 10,    // 总通知数
  "unread": 5     // 未读数
}
``` 