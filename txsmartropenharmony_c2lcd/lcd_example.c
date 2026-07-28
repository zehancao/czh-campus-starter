/*
 * c2_lcd 例程改造版：读取 SHT30 温湿度并显示到板载 LCD（TX-SMART-R / RK2206）
 * 直接覆盖原 c2_lcd/lcd_example.c
 */
#include <stdio.h>
#include "los_task.h"
#include "ohos_init.h"
#include "lcd.h"
#include "sht30.h"

/***************************************************************
* 函数名称: lcd_example_process
* 说    明: 读取 SHT30 温湿度并显示到 LCD
***************************************************************/
void lcd_example_process(void *arg)
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
* 函数名称: lcd_example
* 说    明: 开机自启动调用函数（覆盖原 c2_lcd 入口）
***************************************************************/
void lcd_example(void)
{
    unsigned int thread_id;
    TSK_INIT_PARAM_S task = {0};
    unsigned int ret = LOS_OK;

    task.pfnTaskEntry = (TSK_ENTRY_FUNC)lcd_example_process;
    task.uwStackSize = 20480;   /* LCD + SHT30 需要较大栈 */
    task.pcName = "lcd_example";
    task.usTaskPrio = 24;
    ret = LOS_TaskCreate(&thread_id, &task);
    if (ret != LOS_OK) {
        printf("Falied to create task ret:0x%x\n", ret);
        return;
    }
}

APP_FEATURE_INIT(lcd_example);
