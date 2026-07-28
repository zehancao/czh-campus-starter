# 校园π - czh-campus-starter

校园π是一套面向校园生活服务场景的全栈项目，包含 Spring Boot 后端、鸿蒙端应用和 Web 管理后台。项目覆盖课表、空教室、二手交易、社团活动、拼车、表白墙、校园安全、学习资料共享、投诉审核等功能。

## 分工

| 人 | 负责 | 项目 |
|---|---|---|
| **曹泽涵（组长）** | 后端 + 命名规则 + 传参方式 + 请求方式 + 首页 + | Campus-Server |
| **白雪峰** | 鸿蒙：课表 / 空教室 / 改密码 / 个人中心 | CampusAssistant |
| **谢易霖** | 鸿蒙：商品详情页 / 收藏 / 浏览记录 / 投诉记录 / 失物招领 | CampusAssistant |
| **何隆** | 鸿蒙：聊天 / 社团 /商品发布页 | CampusAssistant |
| **杨晨** | Web 管理员前端 | web-admin |

## 🚀 快速开始

### 后端
```bash
# 1. 导入数据库（MySQL 需要先装好）
mysql -u root --default-character-set=utf8mb4 < campusdb2.sql

# 2. 配置本机环境变量（按需修改）
$env:CAMPUS_DB_PASSWORD="你的数据库密码"
$env:CAMPUS_JWT_SECRET="至少32位的JWT密钥"
$env:CAMPUS_UPLOAD_DIR="./uploads"

# 如果需要反馈邮件功能，再配置邮箱
$env:CAMPUS_MAIL_USERNAME="你的邮箱"
$env:CAMPUS_MAIL_PASSWORD="你的邮箱授权码"
$env:CAMPUS_FEEDBACK_EMAIL="接收反馈的邮箱"

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
git clone git@github.com:bai988/czh-campus-starter.git

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

