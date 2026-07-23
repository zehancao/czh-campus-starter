# 校园助手 - czh-campus-starter

## 分工

| 人 | 负责 | 项目 |
|---|---|---|
| **曹泽涵（组长）** | 后端 + 首页 + 核心文件 + 社团活动3页 + 兜底 | Campus-Server |
| **白雪峰** | 鸿蒙：课表 / 空教室 / 改密码 / 个人中心 | CampusAssistant |
| **谢易霖** | 鸿蒙：商品详情页 / 收藏 / 浏览记录 / 投诉记录 / 失物招领 | CampusAssistant |
| **何隆** | 鸿蒙：聊天 / 社团 /商品发布页 | CampusAssistant |
| **杨晨** | Web 管理员前端 | web-admin |

## 🚀 快速开始

### 后端
```bash
# 1. 导入数据库（MySQL 需要先装好）
mysql -u root --default-character-set=utf8mb4 < campusdb2.sql

# 2. 改数据库密码（如果你的 MySQL 有密码）
#    打开 Campus-Server/src/main/resources/application.yml
#    修改 spring.datasource.password: 你的密码

# 3. 启动 Spring Boot
cd Campus-Server
mvn spring-boot:run
```

### 鸿蒙端
用 DevEco Studio 打开 `CampusAssistant/`

**⚠️ 必须改 API 地址：** 打开 `entry/src/main/ets/service/ApiService.ets`，把 `baseUrl` 改成运行后端电脑的局域网 IP，例如：
```
static baseUrl: string = 'http://192.168.x.x:8080'
```
（手机和电脑必须同一网络，电脑 IP 用 `ifconfig` 或 `ipconfig` 查看）

- API 调用见 `04-api-template.md`
- 接口定义见 `02-api-doc.md`
- 表结构见 `01-database.md`

### Web 管理端
```bash
cd web-admin
npm install
npm run dev
```

---

## 📥 拉取仓库（第一天必做）

```bash
# 克隆到本地
git clone git@github.com:zehancao/czh-campus-starter.git

# 进入项目目录
cd czh-campus-starter

# 开始写代码
```

## 📤 提交代码（每天收工必做）

```bash
# 1. 看看你今天改了什么
git status

# 2. 把所有改动加入暂存
git add .

# 3. 提交，写清楚你做了什么
git commit -m "feat: 完成了课表详情页"

# 4. 推送到 GitHub
git push
```

### 如果 push 报错（别人先推了）

```bash
# 先拉取最新代码
git pull

# 如果有冲突 → 截图发群里 @组长
# 没有冲突 → 再推一次
git push
```

### 提交信息规范

```bash
git commit -m "feat: 新增了xxx功能"       # 新功能
git commit -m "fix: 修复了xxx的bug"       # 修bug
git commit -m "style: 调整了xxx样式"      # 样式调整
```

---

## ⚠️ 铁律

1. **`ApiService.ets` / `AppStore.ets` / `Models.ets` / `WebSocketService.ets` 不许改**
2. **首页（Index.ets / MainPage.ets）组长写，其他人别动**
3. **API 路径必须跟 `02-api-doc.md` 一致**
4. **鸿蒙页面只能放在 `pages/` 目录下**

---

## 参考资料

| 文件 | 谁看 |
|---|---|
| `01-database.md` | 所有人 |
| `02-api-doc.md` | 所有人（特别是杨晨） |
| `03-structure.md` | 所有人 |
| `04-api-template.md` | 白雪峰 / 谢易霖 / 何隆 |

---

## 📄 页面归属（鸿蒙端）

```
pages/
├── Index.ets                ← 组长写的（别动）
├── MainPage.ets             ← 组长写的（别动）
├── AiChatPage.ets           ← 组长写的（别动）
│
├── LoginPage.ets            ← 白雪峰
├── RegisterPage.ets         ← 白雪峰
├── EmptyRoomPage.ets        ← 白雪峰
├── RoomSchedulePage.ets     ← 白雪峰
├── PasswordChangePage.ets   ← 白雪峰
│
├── ProductDetailPage.ets    ← 谢易霖
├── PublishPage.ets          ← 谢易霖
├── MyPublishPage.ets        ← 谢易霖
├── MyFavoritesPage.ets      ← 谢易霖
├── MyHistoryPage.ets        ← 谢易霖
├── MyComplaintsPage.ets     ← 谢易霖
│
├── ChatPage.ets             ← 何隆
├── ConversationListPage.ets ← 何隆
├── LostFoundListPage.ets    ← 何隆
├── LostFoundDetailPage.ets  ← 何隆
├── LostFoundPublishPage.ets ← 何隆
├── MyLostFoundPage.ets      ← 何隆
│
├── ClubActivityListPage.ets    ← 组长
├── ClubActivityDetailPage.ets  ← 组长
├── ClubActivityPublishPage.ets ← 组长
```

---

## 🗣️ 组长对每个人的叮嘱

### 白雪峰（课表 / 空教室 / 改密码 / 个人中心）
- 你的页面数据在 `api/schedule`、`api/classroom`、`api/user` 这三个模块
- 课表要先调 `getCurrentSemester()` 拿到当前学期的 `semesterId`，再调 `getMySchedule(semesterId)`
- 空教室接口是 🔓 白名单，不需要登录就能查，但建议登录后用
- 改密码的 `changePassword(oldPwd, newPwd)` 后端返回 `true/false`，记得处理失败情况
- **首页不要碰，那是组长的**

### 谢易霖（商品 / 收藏 / 浏览 / 投诉 / 发布）
- 你这块接口最密集，**6 页调了 15 个以上接口**，先看 `04-api-template.md` 第 5-7 节
- `publishProduct()` 里 `conditionLevel` 是数字：1=全新 2=几乎全新 3=轻微痕迹 4=明显痕迹 5=成色一般
- 发布商品前要调 `getCreditScore()`，信用分 < 85 发不了
- 商品详情页有个"联系卖家"按钮，跳转到 `ChatPage` 时传 `otherUserId` 和 `productId`——**你跟何隆对好参数名**
- 收藏/浏览记录/投诉都走 Token，用户没登录时显示空白或引导登录

### 何隆（聊天 / 失物招领 / 公告）
- 聊天模块有 WebSocket，`WebSocketService.ets` 已经封装好了，直接 `ws.connect()` 和 `ws.send()` 就行
- `ChatPage` 需要接收来自谢易霖商品详情页的跳转参数 `otherUserId` 和 `productId`——跟他约好
- 失物招领的 `images` 字段后端返回的是 JSON 字符串（`"["url"]"`），不是数组，需要 `JSON.parse()`
- 公告接口虽然标的 🔒，但携带 Token 就能调，不需要 admin 角色
- **社团活动那 3 页不用你做，组长自己写**

### 杨晨（Web 管理员前端）
- 你的项目在 `web-admin/` 目录，独立于鸿蒙端，启动方式不同
- 登录接口是 `/api/user/login`，**不是** `/api/admin/login`——管理员账号需要手动去数据库 `users` 表把 `role` 改成 `admin`
- 课表导入功能需要上传 Excel 文件，`Content-Type: multipart/form-data`，后端已经支持了
- 统计接口 `products-by-category` 返回 `[{ name, value }]`，ECharts 直接能吃
- **Web 端是独立的，跟鸿蒙端的页面无关，放心写**

### 所有人
- `git add .` 之前先 `git status` 看看有没有不小心加了不该加的文件
- 提交信息写清楚干了什么，别写 "update" "fix" 这种
- 推不上去就 `git pull` 再推
- 报错就截图发群 @我
