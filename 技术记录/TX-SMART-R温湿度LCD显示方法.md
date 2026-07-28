# TX-SMART-R 温湿度 LCD 显示（m_app 独立例程）

## 目标
在 TX-SMART-R 开发板（RK2206，OpenHarmony 3.0 LTS / LiteOS-M）的**板载 SPI LCD（320×240，横屏，RGB565）**上实时显示 SHT30 采集的温度与湿度。

## 板子确认
- 主控：瑞芯微 RK2206（Cortex-M4F）
- 屏：板载 SPI LCD，320×240，横屏（`lcd.h` 中 `USE_HORIZONTAL=3` → `LCD_W=320`, `LCD_H=240`）
- 传感器：板载 SHT30，I2C 接口（出厂已接好）
- 系统：OpenHarmony 3.0 LTS 轻量级（LiteOS-M 内核）

## 思路（干净做法）
**不改动任何原有例程**，在 `samples/` 下新建独立 sample `m_app`：
- 从 `c2_lcd` 拷贝 LCD 驱动（显示用）
- 从 `c5_sht30` 拷贝 SHT30 驱动（读数用）
- 自写 `m_app_example.c`，把"读 SHT30 → 画到 LCD"合并到一个任务里

涉及的源文件清单（已确认）：
- `c2_lcd/include/`：`lcd.h` `lcd_font.h` `picture.h`
- `c2_lcd/src/`：`lcd.c` `picture.c`
- `c5_sht30/include/`：`sht30.h`
- `c5_sht30/src/`：`sht30.c`

关键 API：
- LCD（`lcd.h`）：`lcd_init()`、`lcd_fill(x0,y0,x1,y1,color)`、`lcd_show_string(x,y,str,fc,bc,size,mode)`、`lcd_show_chinese(x,y,str,fc,bc,size,mode)`、`lcd_show_float_num1(x,y,val,len,fc,bc,size)`；颜色宏 `LCD_RED/LCD_BLUE/LCD_GREEN/LCD_WHITE`；尺寸宏 `LCD_W/LCD_H`。
- SHT30（`sht30.h`）：`sht30_init()`、`sht30_read_data(double data[2])`，`data[0]=温度(℃)`，`data[1]=湿度(%RH)`。

---

## 步骤（全部在 VM 上执行）

### 0. 复位工程（撤销之前对 c2_lcd / samples / Makefile 的改动）
```bash
cd /home/yc666/txsmartropenharmony
git checkout -- .          # 把所有跟踪文件恢复到原始状态
git status                 # 应显示 clean（无 modified）
```
> 这一步就是"把项目全关了"。之后所有改动只发生在新建的 `m_app/` 目录里。

### 1. 建目录 + 拷贝驱动文件
```bash
cd /home/yc666/txsmartropenharmony/vendor/isoftstone/rk2206/samples
mkdir -p m_app/src m_app/include

# LCD 驱动（来自 c2_lcd）
cp c2_lcd/include/lcd.h      m_app/include/
cp c2_lcd/include/lcd_font.h m_app/include/
cp c2_lcd/include/picture.h   m_app/include/
cp c2_lcd/src/lcd.c          m_app/src/
cp c2_lcd/src/picture.c      m_app/src/

# SHT30 驱动（来自 c5_sht30）
cp c5_sht30/include/sht30.h  m_app/include/
cp c5_sht30/src/sht30.c      m_app/src/
```

### 2. 写 m_app/m_app_example.c
```c
/*
 * m_app: 读取 SHT30 温湿度并显示到板载 LCD（TX-SMART-R / RK2206）
 */
#include <stdio.h>
#include "los_task.h"
#include "ohos_init.h"
#include "lcd.h"
#include "sht30.h"

/***************************************************************
* 函数名称: m_app_process
* 说    明: 读取 SHT30 温湿度并显示到 LCD
***************************************************************/
void m_app_process(void *arg)
{
    double sht30_data[2] = {0};
    unsigned int ret = 0;

    /* 初始化 SHT30 与 LCD */
    sht30_init();
    ret = lcd_init();
    if (ret != 0) {
        printf("lcd_init failed(%d)\n", ret);
        return;
    }

    /* 清屏为白底 */
    lcd_fill(0, 0, LCD_W, LCD_H, LCD_WHITE);

    while (1) {
        /* 读取温湿度 */
        sht30_read_data(sht30_data);
        printf("temperature %.2f RH %.2f \r\n", sht30_data[0], sht30_data[1]);

        /* 每帧先清屏，再绘制 */
        lcd_fill(0, 0, LCD_W, LCD_H, LCD_WHITE);

        /* 标题（中文，需 lcd.c 内嵌 32px 字库；若不显示改下面的 ASCII 版本） */
        lcd_show_chinese(0, 16, "温湿度监测", LCD_RED, LCD_WHITE, 32, 0);
        /* ASCII 备选标题（中文异常时用）：
           lcd_show_string(0, 24, "TEMP/HUMI MONITOR", LCD_RED, LCD_WHITE, 24, 0); */

        /* 温度行 */
        lcd_show_string(10, 80, "Temp:", LCD_BLUE, LCD_WHITE, 24, 0);
        lcd_show_float_num1(90, 80, (float)sht30_data[0], 4, LCD_BLUE, LCD_WHITE, 24);
        lcd_show_string(200, 80, "C", LCD_BLUE, LCD_WHITE, 24, 0);

        /* 湿度行 */
        lcd_show_string(10, 130, "Humi:", LCD_GREEN, LCD_WHITE, 24, 0);
        lcd_show_float_num1(90, 130, (float)sht30_data[1], 4, LCD_GREEN, LCD_WHITE, 24);
        lcd_show_string(200, 130, "%", LCD_GREEN, LCD_WHITE, 24, 0);

        LOS_Msleep(1000);
    }
}

/***************************************************************
* 函数名称: m_app_example
* 说    明: 开机自启动调用函数
***************************************************************/
void m_app_example()
{
    unsigned int thread_id;
    TSK_INIT_PARAM_S task = {0};
    unsigned int ret = LOS_OK;

    task.pfnTaskEntry = (TSK_ENTRY_FUNC)m_app_process;
    task.uwStackSize = 20480;   /* LCD + SHT30 需要较大栈 */
    task.pcName = "m_app";
    task.usTaskPrio = 24;
    ret = LOS_TaskCreate(&thread_id, &task);
    if (ret != LOS_OK) {
        printf("Falied to create task ret:0x%x\n", ret);
        return;
    }
}

APP_FEATURE_INIT(m_app_example);
```

### 3. 写 m_app/BUILD.gn
```gn
static_library("m_app") {
    sources = [
        "m_app_example.c",
        "src/lcd.c",
        "src/picture.c",
        "src/sht30.c",
    ]

    include_dirs = [
        "//utils/native/lite/include",
        "include",
        "//base/iot_hardware/peripheral/interfaces/kits",
    ]

    deps = [
        "//device/rockchip/hardware:hardware",
    ]
}
```

### 4. 改 samples/BUILD.gn（只启用 m_app）
打开 `vendor/isoftstone/rk2206/samples/BUILD.gn`，把 samples 数组改成只剩一行，其余全部注释：
```gn
        "./m_app:m_app",
#       "./c2_lcd:lcd_example",
#       "./c5_sht30:sht30_example",
#       ...（其他例程全部注释掉）
```

### 5. 改 Makefile（device/rockchip/rk2206/sdk_liteos/Makefile）
找到 `hardware_LIBS` 这一行，改成：
```
hardware_LIBS = -lhal_iothardware -lhardware -lm_app
```
（库名 `m_app` 必须和步骤 3 里 `static_library("m_app")` 一致。）

### 6. 编译 + 烧录
```bash
cd /home/yc666/txsmartropenharmony
hb build -f
python3 flash.py          # 烧 out/rk2206/isoftstone-rk2206/images 下产物（按老板已知命令）
```

---

## 预期效果
板子 RESET 后，LCD 屏显示：
- 第一行（红色 32 号中文）：温湿度监测
- 第二行（蓝色）：Temp: 32.40 C
- 第三行（绿色）：Humi: 48.89 %
每秒刷新一次；串口仍保留打印，便于调试。

## 注意事项 / 排错
- **中文标题不显示**：`lcd.c` 可能未内嵌 32px 中文字库。把 `m_app_example.c` 里的 `lcd_show_chinese(...)` 注释掉，改用已验证可用的 `lcd_show_string(...,"TEMP/HUMI MONITOR",...)`（原 c2_lcd 例程就是用 `lcd_show_string` 显示英文的）。
- **任务栈**：必须用 `20480`（原 sht30 例程仅 2048，合并后栈不够会跑飞）。
- **`sht30_read_data` 返回 `double`**：画屏时强转 `float`，即 `(float)sht30_data[0]`。
- **编译报 `sht30_example` / `lcd_example` 未定义**：说明 `samples/BUILD.gn` 或 Makefile 还残留旧例程，回到步骤 4/5 确认只留 `m_app`。
- 若想换布局（加图标、改字号、横竖屏），改 `lcd.h` 的 `USE_HORIZONTAL` 与 `m_app_example.c` 里的坐标即可。

## 旧方案（不推荐，保留参考）
早期方案是把 SHT30 合并进 `c2_lcd`（改 c2_lcd/lcd_example.c、c2_lcd/BUILD.gn、samples/BUILD.gn、Makefile）。当前已改为独立 `m_app` 例程，不再污染原有例程。
