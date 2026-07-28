/*
 * SHT30 温湿度传感器驱动（TX-SMART-R / RK2206，I2C0 0x44）
 * 移植自 c5_sht30 例程，放入 c2_lcd/src/
 */
#include <stdio.h>
#include "ohos_init.h"
#include "iot_i2c.h"
#include "iot_gpio.h"
#include "sht30.h"

#define SHT30_I2C_PORT     EI2C0_M2
#define SHT30_I2C_ADDRESS  0x44

/* SHT30 数据 CRC8 校验（多项式 0x31，初值 0xFF） */
static unsigned char crc8(const unsigned char *data, int len)
{
    unsigned char crc = 0xFF;
    int i, j;
    for (i = 0; i < len; i++) {
        crc ^= data[i];
        for (j = 0; j < 8; j++) {
            if (crc & 0x80) {
                crc = (unsigned char)((crc << 1) ^ 0x31);
            } else {
                crc = (unsigned char)(crc << 1);
            }
        }
    }
    return crc;
}

void sht30_init(void)
{
    unsigned char cmd[2] = {0x22, 0x36};  /* 周期测量, 1 mps, 高重复性 */
    IoTi2cWrite(SHT30_I2C_PORT, SHT30_I2C_ADDRESS, cmd, 2);
}

void sht30_read_data(double *dat)
{
    unsigned char cmd[2] = {0xE0, 0x00};  /* Fetch Data */
    unsigned char buf[6] = {0};
    unsigned short t, rh;

    IoTi2cWrite(SHT30_I2C_PORT, SHT30_I2C_ADDRESS, cmd, 2);
    IoTi2cRead(SHT30_I2C_PORT, SHT30_I2C_ADDRESS, buf, 6);

    if (crc8(buf, 2) != buf[2] || crc8(buf + 3, 2) != buf[5]) {
        printf("sht30 crc error\n");
        return;
    }

    t  = (unsigned short)((buf[0] << 8) | buf[1]);
    rh = (unsigned short)((buf[3] << 8) | buf[4]);

    dat[0] = -45.0 + 175.0 * (double)t / 65535.0;   /* ℃   */
    dat[1] = 100.0 * (double)rh / 65535.0;          /* %RH */
}
