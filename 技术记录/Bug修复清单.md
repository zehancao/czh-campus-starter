# Bug 修复清单

> 🔴高危　🟡中危　🟢低危

---

## 复核状态（2026-07-24 二次核对）

逐项对照当前代码复核，结论：

- ✅ **确认存在、建议修复**：#1 #2 #3 #4 #5 #7 #8 #9 #10 #11 #12 #13 #15 #16 #18 #20 #21 #22 #23 #24 #25 #26 #27 #28（共 24 项）
- ⚠️ **误报 / 已规避（不要照清单改）**：
  - ~~**#14 teacher vs teacherName —— 误报**~~。链路自洽（前端传 `teacher`、后端读 `teacher`、实体字段 `teacher`、Service 再映射 `teacherName`），照清单改成 `teacherName` 反而保存空教师。
  - ~~**#17 商品图片 `as string[]` —— 已规避**~~。后端 `ProductService.toVO` 已把 JSON 拆成 `String[]` 返回，前端 `as string[]` 正确。
  - ~~**#19 失物详情 null 检查 —— 基本误报**~~。页面已有 `result.data==null`、`lf.images!=null`、`store.isLoggedIn` 等判空，后端 `LostFoundVO.images` 是字符串、`splitImageString` 按字符串处理，列表页也按字符串解析（此前"图片修复"已覆盖）。
- 🔍 **需进一步验证（1 项）**：#6 WebSocket `on('message')` 是否真废弃取决于本地 HarmonyOS SDK 版本，建议用编译环境 SDK 版本确认后再改。
- 🆕 **查漏补缺新发现 7 项**：见末尾「十、二次核对新发现」N1–N7。

---

## 一、商品模块

### Bug #1 — MyHistoryPage 跳转错误 🔴高危 
- **文件**: `CampusAssistant/entry/src/main/ets/pages/MyHistoryPage.ets:184-188`
- **问题**: `goToDetail()` 跳转到 `pages/MainPage` 而非 `pages/ProductDetailPage`，浏览历史点击后进入主页
- **修复**: 改为 `router.pushUrl({ url: 'pages/ProductDetailPage', params: { id: item.id.toString() } })`

### Bug #13 — ProductVO 缺少 categoryName 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/dto/ProductVO.java`
- **问题**: 前端商品模型有 `categoryName` 但后端 ProductVO 不返回，分类名始终为空
- **修复**: ProductVO 增加 `categoryName` 字段，在 ProductService 中查询时关联 product_categories 表填充

### Bug #16 — viewCount 竞态条件 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ProductService.java:76-77`
- **问题**: read-then-update 模式，并发请求丢失计数
- **修复**: 改为 `UPDATE products SET view_count = view_count + 1 WHERE id = #{id}`

### ~~Bug #17 — parseProductList images 强转失败~~ ✅**已规避（无需修）**
- **文件**: `CampusAssistant/entry/src/main/ets/service/ApiService.ets:369-371`
- **原报告**: `item.images = imagesObj as string[]` 强转，若后端返回 JSON 字符串则图片显示失败
- **复核结论（2026-07-24）**: **已规避**。后端 `ProductService.toVO` 已把 JSON 字符串拆成 `String[]` 再返回，前端 `as string[]` 在此时是正确的，不会崩。
- **处理**: 保持现状，不修复。

### Bug #18 — parseFavoriteList 解析脆弱 🟡中危 
- **文件**: `CampusAssistant/entry/src/main/ets/service/ApiService.ets:415-423`
- **问题**: 用 `replace('[','').replace(']','')` 解析 JSON 数组，URL 含逗号/方括号时崩溃
- **修复**: 统一用 `JSON.parse()` 解析 images 字段，与 Bug #17 合并处理

### Bug #22 — 三个上传方法代码重复 🟡中危 
- **文件**: `CampusAssistant/entry/src/main/ets/service/ApiService.ets:170-208, 573-610, 612-650`
- **问题**: uploadImage/uploadAvatar/uploadClubCover 代码几乎完全重复
- **修复**: 抽取通用 `uploadFile(endpoint: string, srcPath: string)` 方法，三个上传方法调用它

### Bug #23 — searchProducts 全表内存过滤 🟡中危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ProductService.java:40-53`
- **问题**: 先加载全部商品再 Java 过滤，数据量大时性能差
- **修复**: 用 MyBatis-Plus QueryWrapper 加 WHERE 条件在数据库层过滤

---

## 二、失物招领模块

### ~~Bug #19 — LostFoundDetailPage 参数无 null 检查~~ ⚠️**基本误报（已覆盖）**
- **文件**: `CampusAssistant/entry/src/main/ets/pages/LostFoundDetailPage.ets:79`
- **原报告**: `router.getParams()` 未做 null 检查，无参数时崩溃
- **复核结论（2026-07-24）**: **基本误报**。页面已有 `result.data == null`、`lf.images != null`、`store.isLoggedIn` 等判空；后端 `LostFoundVO.images` 是字符串、`splitImageString` 按字符串处理，列表页 `getFirstImageUrl` 同样按字符串解析（此前"图片修复"已覆盖）；`router.getParams()` 拿的是被 push 进来的 params，缺参数场景风险低。
- **处理**: 保持现状，不修复（如仍想加固可补一行 `getParams` 空判断，但非必须）。

---

## 三、社团活动模块

### Bug #12 — 每次查询删除过期活动 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ClubActivityService.java:133-143`
- **问题**: `cleanExpiredActivities` 在每次 getList/getMyActivities 时调用，直接删除过期活动及报名记录
- **修复**: 改为逻辑删除（status=0 标记过期）或用定时任务清理，查询时用 WHERE 过滤过期数据

### Bug #24 — ClubActivityService N+1 查询 🟡中危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ClubActivityService.java:145-179`
- **问题**: toVO 中每条活动查 User，再查所有 Registration，每条 Registration 再查 User
- **修复**: 批量查询 User（按 userId 列表），批量查询 Registration，在内存中组装

---

## 四、投诉/信用模块

### Bug #11 — 投诉提交即扣信用分 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ComplaintService.java:27-42`
- **问题**: 提交投诉立即扣被投诉人 -5 信用分，恶意投诉可攻击他人
- **修复**: 提交时仅记录投诉，扣分移到 `processComplaint` 管理员审核通过后再执行

---

## 五、课表模块

### ~~Bug #14 — addPersonalCourse 字段名不一致 teacher vs teacherName~~ ⚠️**误报（不要改）**
- **文件**: `Campus-Server/src/main/java/com/campus/controller/ScheduleController.java:59`
- **原报告**: 后端读取 `params.get("teacher")`，但前端 CourseSchedule 模型字段是 `teacherName`，前端发送 key 为 `teacherName` 则后端读不到教师名，添课时教师名丢失
- **复核结论（2026-07-24）**: **误报**。实际整条链路自洽：
  - 前端 `AddCoursePage` 第 192 行传的就是 `teacher`
  - 后端 `ScheduleController` 第 59 行读 `teacher`、`PersonalTimetable` 实体字段也是 `teacher`
  - `ScheduleService` 第 75 行再映射为 `teacherName` 用于展示
  - 若照清单改成 `teacherName`，后端读不到值，反而保存空教师。
- **处理**: 保持现状，不修复。

### Bug #21 — 课表页"切回本周"按钮位置硬编码 🟡中危 
- **文件**: `CampusAssistant/entry/src/main/ets/pages/SchedulePage.ets:264`
- **问题**: `Button('切回本周')` 使用 `position({ x: 292, y: 610 })` 硬编码，在不同屏幕尺寸设备上位置偏移，可能超出可视区域
- **修复方案**: 去掉 position 硬编码，改用相对定位方案（如放在课表网格下方的 Row 中靠右对齐，或用 Stack + `.alignContent(Alignment.BottomEnd)` + margin）
- **验证**: 在不同宽度设备/模拟器上查看课表页，按钮应始终可见且位置合理

### Bug #28 — SchedulePage 课程网格动态高度 Stack 撑满问题 🟢低危 
- **文件**: `CampusAssistant/entry/src/main/ets/pages/SchedulePage.ets`
- **背景**: 此前多次修复过动态高度 Stack 内子元素 height('100%') 撑爆问题，但课表网格中课程卡片的高度计算仍可能在不同设备上出问题
- **修复方案**: 确保课程卡片不用 `height('100%')`，改用 `constraintSize({ minHeight: ... })` 或由父容器固定高度
- **验证**: 在不同屏幕尺寸设备上查看课表页，课程卡片不应超出网格区域

---

## 六、用户/认证模块

### Bug #4 — 修改密码页用 changePassword(old, old) 验证旧密码 🔴高危 
- **文件**: `CampusAssistant/entry/src/main/ets/pages/PasswordChangePage.ets:42`
- **问题**: `verifyOldPassword()` 调用 `ApiService.changePassword(old, old)` 来验证旧密码，实际触发了密码修改操作（虽然改成自身，但有副作用风险：如后端两次密码相同时返回错误则验证逻辑失效）
- **修复方案**:
  1. 前端不在提交前调用 changePassword 验证旧密码，改为仅在"确认修改"时一次调用 `changePassword(old, new)`
  2. 或后端新增 `POST /api/user/verify-password` 专用于旧密码校验，前端调用该接口验证后再修改
- **验证**: 修改后测试——输入正确旧密码+新密码应成功；输入错误旧密码应提示失败

### Bug #5 — AppStore 属性非响应式 🔴高危 
- **文件**: `CampusAssistant/entry/src/main/ets/service/AppStore.ets:7-10`
- **问题**: `token`, `userInfo`, `isLoggedIn` 为普通属性，非 `@State`，页面读取时不触发 UI 刷新
- **修复**: AppStore 本身无法用 @State（非组件），需在各页面用 `@State` 本地变量 + `onPageShow` 同步；或改用 AppStorageV2 / LocalStorage

### Bug #7 — AdminController 返回含 password 的 User 实体 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/controller/AdminController.java:166-169`
- **问题**: `getAllUsers()` 返回完整 User 实体，包含 BCrypt 哈希密码
- **修复**: 创建 AdminUserVO（不含 password），在 service 层做转换后返回

---

## 七、聊天/消息模块

### Bug #6 — WebSocket 使用废弃 API 🔴高危 🔍**待 SDK 版本确认**
- **文件**: `CampusAssistant/entry/src/main/ets/service/WebSocketService.ets`
- **问题（需确认）**: 代码使用 `ws.on('message', (err, value) => {...)` 监听消息。在较高版本 HarmonyOS SDK 中该回调签名可能已被废弃，建议改用 `ws.on('messageReceive', (value) => {...})`。
- **复核说明（2026-07-24）**: 原报告写"import 路径废弃"不准确，`@ohos.net.webSocket` 仍可导入；真正需确认的是 `on('message')` 回调是否在本机 SDK 版本报废弃。
- **修复**: 用本机编译环境的 SDK 版本确认后，将 `on('message')` 改为 `messageReceive` 回调（注意参数少一个 err）。

### Bug #8 — sendMessage 未验证发送者是否为会话参与者 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ChatService.java:65-83`
- **问题**: `sendMessage(userId, conversationId, content)` 未检查 userId 是否为该会话的参与者，任何登录用户可向任何会话发消息
- **修复方案**: 在 sendMessage 开头查询 conversation 并验证 `userId == conversation.getUser1Id() || userId == conversation.getUser2Id()`，不满足则抛异常
- **验证**: 用用户 A 的 token 尝试向用户 B 和 C 的会话发消息，应返回 400 错误

### Bug #9 — getMessages 未验证用户权限 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/ChatService.java:47-63`
- **问题**: `getMessages(userId, conversationId)` 未检查 userId 是否为会话参与者，任何用户可读取任何会话的消息
- **修复方案**: 在 getMessages 开头查询 conversation 并验证 `userId == conversation.getUser1Id() || userId == conversation.getUser2Id()`，不满足则抛异常
- **验证**: 用用户 A 的 token 尝试获取用户 B 和 C 的会话消息，应返回 403/400 错误

### Bug #20 — ConversationVO 不返回对方头像 🟡中危 
- **文件**: `Campus-Server/src/main/java/com/campus/dto/ConversationVO.java`
- **问题**: 前端 Conversation 模型有 `otherUserAvatar` 字段，但后端 ConversationVO 不返回该字段，聊天列表无法显示对方头像
- **修复方案**:
  1. ConversationVO 增加 `otherUserAvatar` 字段
  2. ChatService.toVO 方法中查询对方用户的 avatar 并设置到 VO
- **验证**: 登录后查看消息列表，每个会话应显示对方头像

---

## 八、网络请求基础设施

### Bug #2 — JSON.parse 无 try-catch 🔴高危 
- **文件**: `CampusAssistant/entry/src/main/ets/service/ApiService.ets:42-43`
- **问题**: `JSON.parse(resultStr)` 无保护，后端返回非 JSON 时直接崩溃
- **修复**: 包裹 try-catch，catch 中返回 `{ code: -1, msg: '数据解析失败' }`

### Bug #3 — 网络错误无用户提示 🔴高危 
- **文件**: `CampusAssistant/entry/src/main/ets/service/ApiService.ets:45-48`
- **问题**: catch 块返回 `{code:-1, msg:'网络错误'}`，调用方只检查 `code===200`，用户看到空页面
- **修复**: 各页面调用方在 `code !== 200` 时用 `promptAction.showToast({ msg: result.msg || '请求失败' })` 提示用户

---

## 九、安全/配置模块

### Bug #10 — 三个上传接口无文件类型校验 🔴高危 
- **文件**:
  - `Campus-Server/src/main/java/com/campus/controller/UserController.java:64-88`
  - `Campus-Server/src/main/java/com/campus/controller/ProductController.java:93-115`
  - `Campus-Server/src/main/java/com/campus/controller/ClubActivityController.java:49-72`
- **问题**: 无扩展名白名单，可上传 .jsp/.exe 等危险文件
- **修复**: 在三个方法中添加扩展名校验：`Set<String> ALLOWED = Set.of("jpg","jpeg","png","gif","webp"); if (!ALLOWED.contains(ext)) return Result.error("不支持的文件类型");`

### Bug #15 — 反馈内容 XSS 漏洞 🔴高危 
- **文件**: `Campus-Server/src/main/java/com/campus/service/FeedbackService.java:29-35`
- **问题**: 用户输入直接嵌入 HTML 邮件，可注入脚本
- **修复**: 对 userName/contact/content 做 HTML 转义（`<` → `&lt;` 等）或使用模板引擎

### Bug #25 — CORS 允许任意源+凭证 🟡中危 
- **文件**: `Campus-Server/src/main/java/com/campus/config/CorsConfig.java:15`
- **问题**: `addAllowedOriginPattern("*")` + `setAllowCredentials(true)`，CSRF 风险
- **修复**: 将 `*` 改为具体前端域名（如 `http://localhost:8080`），或开发环境用 `*` 但关闭 credentials

### Bug #26 — JwtAuthFilter 白名单逻辑复杂 🟡中危 
- **文件**: `Campus-Server/src/main/java/com/campus/config/JwtAuthFilter.java:29`
- **问题**: product 路径白名单用字符串拼接+排除法判断，易出错难维护
- **修复**: 改用 AntPathMatcher 或统一白名单列表 + 精确路径匹配

### Bug #27 — 敏感配置硬编码 🟡中危 
- **文件**: `Campus-Server/src/main/resources/application.yml:12-13, 36`
- **问题**: JWT 密钥、邮箱凭证硬编码在 yml 中
- **修复**: 改为环境变量 `${JWT_SECRET}` / `${MAIL_PASSWORD}` 或使用配置中心

---

## 十、二次核对新发现（查漏补缺 · 2026-07-24）

> 以下为对照原清单之外，额外扫描前后端发现的问题。

### Bug N1 — CORS 预检请求可能被 JwtAuthFilter 拦截 🟡中危
- **文件**: `Campus-Server/src/main/java/com/campus/config/CorsConfig.java` + `JwtAuthFilter.java`
- **问题**: 项目用 `WebMvcConfigurer.addCorsMappings`（拦截器实现），对浏览器 `OPTIONS` 预检不生效；而 `JwtAuthFilter` 是 Servlet 过滤器，对未放行（如 `/api/product/publish`）的预检请求因无 token 返回 401，导致带鉴权的写接口跨域失败。
- **修复**: 改用 `CorsFilter` Bean（过滤器优先级高于业务过滤器），或在 `JwtAuthFilter` 中对 `OPTIONS` 请求直接放行。

### Bug N2 — 反馈接口免登录且无频控（邮件轰炸风险） 🟡中危
- **文件**: `Campus-Server/src/main/java/com/campus/service/FeedbackService.java`
- **问题**: `/api/feedback` 在白名单免登录，且 `FeedbackService` 直接发邮件给管理员，任何人可匿名高频提交刷管理员邮箱。
- **修复**: 反馈接口要求登录，或加 IP/账号级提交频率限制（如 Redis 计数），并对 content 长度设上限。

### Bug N3 — WebSocket 在线状态非响应式 🟡中危
- **文件**: `CampusAssistant/entry/src/main/ets/service/WebSocketService.ets`
- **问题**: `_onlineUsers` / `_connectionState` 为普通属性，在线绿点等 UI 不刷新（与 #5 同源但独立表现）。
- **修复**: 改 `@Observed` 类 + `@ObjectLink`，或用 `AppStorage` 暴露在线状态供页面订阅。

### Bug N4 — WebSocket 断线丢消息 🟢低危
- **文件**: `CampusAssistant/entry/src/main/ets/service/WebSocketService.ets`
- **问题**: `send()` 未连接时静默丢弃，无本地队列/重连补发。
- **修复**: 未连接时入本地发送队列，连接建立后补发；断线自动重连。

### Bug N5 — 浏览量用 updateById 覆盖整行 🟢低危
- **文件**: `Campus-Server/src/main/java/com/campus/service/ProductService.java`
- **问题**: `getProductDetail` 用 `updateById` 覆盖整行，且自己看自己的商品也 +1，统计偏。
- **修复**: 用 `LambdaUpdateWrapper` 仅自增 `view_count`，并排除当前用户自己浏览。

### Bug N6 — create-conversation 未校验对方用户是否存在 🟢低危
- **文件**: `Campus-Server/src/main/java/com/campus/controller/ChatController.java:62`
- **问题**: 直接 `Long.valueOf` 解析对方 userId 建会话，对方不存在会建出"幽灵会话"。
- **修复**: 建会话前查 `userMapper.selectById`，不存在返回错误。

### Bug N7 — 聊天发送后对方未读/在线不主动刷新 🟢低危
- **文件**: `CampusAssistant/entry/src/main/ets/pages/ChatPage.ets`（依赖轮询）
- **问题**: 发送消息后依赖轮询刷新对方未读/在线状态，体验弱（功能可用）。
- **修复**: 通过 WebSocket 推送已读回执/在线事件，主动刷新列表。

---

## 统计

> 说明：原清单 28 项经复核，#14 / #17 / #19 为误报或已规避，不计入"待修复"；#6 保留为高危但需 SDK 版本确认。新增查漏补缺 N1–N7（3 中危 + 4 低危）。

| 分类 | 数量（原清单待修复） | 数量（含新发现 N1–N7） |
|------|------|------|
| 🔴高危 | 15 | 15 |
| 🟡中危 | 9 | 12 |
| 🟢低危 | 1 | 5 |
| **合计（待修复）** | **25** | **32** |
| ⚪误报/已规避（不修） | — | #14 #17 #19（3 项） |

---

## 修复指引

### 后端修改流程
1. 修改 Java 代码后需重启 Spring Boot 服务
2. 涉及 DTO/VO 变更的，确认前端 ApiService 中的 parse 方法同步更新
3. 涉及数据库字段变更的，需同步执行 ALTER TABLE

### 前端修改流程
1. 修改 .ets 文件后先运行 `arkts_check` 检查语法
2. 再运行 `build_project` 编译验证
3. 最后用 `start_app` 在设备上测试

### 代码规范
- ArkTS 中禁止使用 `any`/`unknown`、`as` 类型断言、动态属性访问
- 对象字面量必须有显式类型上下文
- 后端 Controller 参数推荐使用 DTO + `@Valid`，避免 `Map<String, Object>`
- 所有 API 调用应做错误处理和 null 检查
