# Mac 端部署技术文档（校园数据大屏 · 开发板温湿度光照接入）

> 适用对象：使用 macOS 的协作成员
> 配套仓库：`czh-campus-starter`（含 Campus-Server 后端 / web-admin 前端 / tools 中继脚本）
> 文档目标：在 Mac 上把「RK2206 开发板 → 中继 → 后端 → 数据库 → 数据大屏」整条链路跑通

---

## 0. 结论先行

**核心数据链路在 Mac 上完全可用。** 中继脚本本身跨平台（仅依赖 `pyserial` + Python 标准库，串口名是参数），后端（Java/Maven）、前端（npm）、MySQL 也全部跨平台。

Mac 与 Windows 的**唯一实质差异**有 3 处：

| 项目 | Windows | macOS | 处理方式 |
|---|---|---|---|
| 串口名 | `COM7` | `/dev/cu.usbserial-XXXX` | 启动时换端口参数 |
| 启动脚本 | `启动中继.bat`（批处理） | 不支持 `.bat` | 直接跑 `python3` 或见文末 `.sh` |
| 上传目录 | `application.yml` 写死 `/Users/caozehan/...` | 其他用户名不存在该路径 | 改成自己路径或用环境变量 |

> ⚠️ 另有**密码明文**问题（见第 7 节），上 GitHub 前必须处理，否则既泄露又让他人连不上库。

---

## 1. 系统架构与数据流

```
RK2206 开发板 (printf 串口)
   │  "temperature 32.8 RH 48.0 lux 428.3"  @115200
   ▼
[常开主机] sensor_relay.py  （读串口 → 解析 → POST JSON）
   │  POST /api/public/sensor/temphumi
   ▼
Campus-Server (Spring Boot :8080)  →  MySQL(campusdb2.sensor_temp_humi)
   │
   ▼
web-admin (Vue :5173)  每 5 秒轮询  →  数据大屏 Screen.vue
```

Mac 上整条链路无需改动即可工作，只需把"常开主机"换成 Mac、串口名换成 Mac 的。

---

## 2. 环境准备（Mac）

| 组件 | 版本要求 | 安装方式（Mac） | 用途 |
|---|---|---|---|
| Python | 3.10+ | 系统自带 或 `brew install python` | 跑中继脚本 |
| pyserial | 最新 | `pip3 install pyserial` | 读串口 |
| Java (JDK) | 17 | `brew install openjdk@17` | 跑后端 |
| Maven | 3.8+ | `brew install maven` | 构建后端 |
| Node.js | 18+ | `brew install node` | 跑前端 |
| MySQL | 8.0 | `brew install mysql` 或 MySQL 官方 dmg | 存传感器数据 |

验证：
```bash
python3 --version
java -version
mvn -version
node -v
mysql --version
```

---

## 3. 第一步：获取代码

```bash
git clone <你们的仓库地址> czh-campus-starter
cd czh-campus-starter
```

> 注意：仓库里**不含开发板固件源码**（带光照 BH1750 的 `m_app` 在 Windows 机的 `D:\famousman\samples`，未入库）。
> 因此 Mac 成员拿到的是「已烧好固件的板子 + 软件工程」；若需重烧固件，需另找固件源码与 OpenHarmony 编译环境（见第 6 节）。

---

## 4. 第二步：数据库（MySQL）

```bash
# 启动 MySQL（brew 安装的话）
brew services start mysql
# 或手动：mysql.server start

# 登录后建库并导入表结构
mysql -u root -p
```
```sql
CREATE DATABASE IF NOT EXISTS campusdb2
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EXIT;
```
```bash
# 导入建表脚本（含 sensor_temp_humi 表，已带 light 列）
mysql -u root -p campusdb2 < campusdb2.sql
```

验证表已建：
```bash
mysql -u root -p campusdb2 -e "DESCRIBE sensor_temp_humi;"
```
应看到 `id / temp / humidity / light / device_id / create_time` 六列。

---

## 5. 第三步：后端 Campus-Server（关键改动）

```bash
cd Campus-Server
```

**改配置**（Mac 必做）：编辑 `src/main/resources/application.yml`

1. **数据库密码/地址**：改成你本机 MySQL 的账号密码（默认 `root` / 你的密码）。
2. **上传目录**（否则文件上传功能报错）：把
   ```yaml
   file:
     upload-dir: /Users/caozehan/Campus-Server/uploads
   ```
   改成你自己的路径，例如：
   ```yaml
   file:
     upload-dir: /Users/你的用户名/Campus-Server/uploads
   ```
   > 此项只影响"文件上传"功能；温湿度/光照大屏不依赖它，不改成也会正常显示。

启动后端：
```bash
mvn spring-boot:run
# 或先打包：mvn clean package -DskipTests && java -jar target/*.jar
```
看到 `Started CampusApplication` 且端口 `8080` 即成功。
接口确认：
```bash
curl -X POST http://localhost:8080/api/public/sensor/temphumi \
  -H "Content-Type: application/json" \
  -d '{"temp":25.5,"humidity":60.1,"light":321.0,"deviceId":"test"}'
```
返回 `200` 且数据库多一条记录即通。

---

## 6. 第四步：前端 web-admin

```bash
cd web-admin
npm install
npm run dev
```
打开 `http://localhost:5173` → 默认直接进**数据大屏**（根路径已重定向到 `/screen`，免登录）。
右上角"管理后台登录 ›"可进登录页，登录后到 `/dashboard`。

> 当前大屏含 8 项一行：温度 / 湿度 / 光照 / 注册用户 / 公告 / 失物 / 反馈 / 近 7 日公告图表。

---

## 7. 第五步：开发板固件说明（重要）

- **已烧好固件的板子**：插上 Mac 的 USB 即可，板子会每秒 `printf` 一行温湿度光照数据。
- **固件源码位置**：带光照(BH1750)的 `m_app` 在 **Windows 机 `D:\famousman\samples`**，**未进入本仓库**。
  - 因此本仓库无法在 Mac 上重新编译/烧录固件。
  - 若需修改固件或给裸板烧录，需另拿到固件源码 + OpenHarmony 编译环境（Linux 虚拟机 + `hb build -f` + 烧录工具）。
- **板子串口输出格式**（中继脚本靠它解析）：
  ```
  temperature 32.80 RH 48.00 lux 428.33
  ```
  正则：`temperature\s+([-\d.]+)\s+RH\s+([-\d.]+)(?:\s+lux\s+([-\d.]+))?`

---

## 8. 第六步：Mac 启动中继（核心差异）

### 8.1 找到 Mac 的串口名
插上板子后，在终端执行：
```bash
ls /dev/cu.usb*
```
典型输出：`/dev/cu.usbserial-0001` 或 `/dev/cu.SLAB_USBtoUART`。**复制这个路径**。

### 8.2 安装依赖
```bash
pip3 install pyserial
```

### 8.3 启动（替换成你的串口名）
```bash
cd tools
python3 sensor_relay.py \
  --port /dev/cu.usbserial-0001 \
  --url http://localhost:8080/api/public/sensor/temphumi
```
成功输出（每秒一行）：
```
[中继] 串口=/dev/cu.usbserial-0001 波特率=115200 上报地址=http://localhost:8080/api/public/sensor/temphumi 设备=rk2206-01
[中继] 已打开串口 /dev/cu.usbserial-0001
[中继] 上报成功 HTTP 200  temp=32.8 humidity=48.0 lux=428.3
```

### 8.4 （可选）一键启动脚本 `启动中继.sh`
仓库内 Windows 用的是 `启动中继.bat`，Mac 用不了。可在 `tools/` 自建一个 `启动中继.sh`：

```bash
#!/bin/bash
# Mac/Linux 一键启动串口中继
cd "$(dirname "$0")"
PORT=$(ls /dev/cu.usbserial-* 2>/dev/null | head -n1)
if [ -z "$PORT" ]; then
  echo "未检测到 USB 串口，请确认开发板已通过 USB 连接 Mac"
  exit 1
fi
echo "自动检测到串口: $PORT"
python3 sensor_relay.py --port "$PORT" --url http://localhost:8080/api/public/sensor/temphumi
```
赋予执行权限后使用：
```bash
chmod +x 启动中继.sh
./启动中继.sh
```

---

## 9. Mac 专属注意事项清单（排查用）

| 现象 | 原因 | 解决 |
|---|---|---|
| 中继报"打开串口失败" | 用了 `COM7` | 改成 `/dev/cu.usbserial-XXXX` |
| `command not found: python` | Mac 默认是 `python3` | 用 `python3` |
| 后端启动后文件上传报错 | `upload-dir` 写死成他人路径 | 改成自己的 `/Users/用户名/...` |
| 大屏空白/无数据 | 中继没起 或 后端没起 或 库没建 | 按顺序检查第 4/5/8 步 |
| 数据库连不上 | 密码/地址不对 | 改 `application.yml` 的 datasource |
| 板子无输出 | 固件未烧 / 未插 USB / 波特率非 115200 | 确认板子已烧带光照固件、USB 连接、波特率 115200 |

---

## 10. 验证整条链路

1. 中继窗口在刷 `上报成功 HTTP 200 ...`
2. 数据库有数据：
   ```bash
   mysql -u root -p campusdb2 -e "SELECT * FROM sensor_temp_humi ORDER BY create_time DESC LIMIT 1;"
   ```
3. 浏览器打开大屏，温度/湿度/光照三张卡有实时数值（用手捂 SHT30 / 挡 BH1750，数秒后变化）

---

## 11. 上 GitHub 协作前必做（安全 + 可用性）

当前 `application.yml` 含**明文密码**（数据库、邮件、JWT）且**未加入 `.gitignore`**，上传会泄露且他人连不上。
建议（详见 Windows 端发布准备）：
- 把 `application.yml` 改为模板 `application.example.yml` + 用环境变量读取真实密码；
- 真实 `application.yml` 加入 `.gitignore`；
- `upload-dir` 改为 `${UPLOAD_DIR:/tmp/campus-uploads}` 这类可配置值；
- 固件 `m_app` 源码考虑一并入库（目前缺失，裸板无法重烧）。

---

## 附：默认接口一览

| 方法 | 路径 | 说明 | 鉴权 |
|---|---|---|---|
| POST | `/api/public/sensor/temphumi` | 接收板子数据（temp/humidity/light/deviceId） | 免登录 |
| GET | `/api/admin/stats/sensor-latest` | 最新一条传感器数据 | 需登录 |
| GET | `/api/admin/stats/sensor-history` | 历史传感器数据 | 需登录 |

> 数据保留策略：插入后表超 100 条会滚动清理最旧记录；`id` 自增到 1000 时清空表并重置回 1。
