# 校园助手 - czh-campus-starter

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

