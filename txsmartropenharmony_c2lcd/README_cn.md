# c2_lcd 集成 SHT30 方案（TX-SMART-R 温湿度 LCD 显示）

老板决定放弃新建 `m_app`，改为**直接在 c2_lcd 例程里集成 SHT30**（旧方案）。
本目录是改造后的可交付文件。

## 本目录已提供（可直接用 / 覆盖）
- `lcd_example.c` —— 覆盖原 `c2_lcd/lcd_example.c`（读温湿度 + 画 LCD）
- `BUILD.gn`      —— 覆盖原 `c2_lcd/BUILD.gn`（sources 增加 `src/sht30.c`）
- `include/sht30.h` —— 放到 `c2_lcd/include/`
- `src/sht30.c`    —— 放到 `c2_lcd/src/`

## 在 VM 上执行（cd 到 samples/c2_lcd）
1. 放入 SHT30 驱动（小文件，可手敲/覆盖，也可 cp）：
   ```bash
   cp ../../c5_sht30/include/sht30.h include/
   cp ../../c5_sht30/src/sht30.c      src/
   ```
2. 用本目录的 `lcd_example.c`、`BUILD.gn` 覆盖 c2_lcd 同名文件。
3. LCD 大文件不用动（`lcd.c`/`lcd_font.h`/`picture.c`/`picture.h` 本就在 c2_lcd 里）。

## 收尾配置
- `samples/BUILD.gn`：只启用 `"./c2_lcd:lcd_example"`，其余注释掉。
- `device/rockchip/rk2206/sdk_liteos/Makefile`：
  `hardware_LIBS = -lhal_iothardware -lhardware -llcd_example`
  （库名 `lcd_example` 必须与 c2_lcd/BUILD.gn 的 `static_library("lcd_example")` 一致）
- `hb build -f` → `python3 flash.py`

## 纯 VM 内执行（不传文件，推荐用 heredoc 写文件）
不通过 scp 传文件，直接在 VM 终端里把代码写进文件（比 vi 粘贴长代码稳）：
```bash
cd /home/yc666/txsmartropenharmony/vendor/isoftstone/rk2206/samples/c2_lcd

# 1. 放 SHT30 驱动（仍在 VM 内，从 c5_sht30 复制）
cp ../../c5_sht30/include/sht30.h include/
cp ../../c5_sht30/src/sht30.c      src/

# 2. 用 heredoc 写入 lcd_example.c（把下面代码块粘到终端，注意只贴代码、不含 ``` 围栏）
cat > lcd_example.c << 'EOF'
<此处粘贴 lcd_example.c 完整代码>
EOF

# 3. 写入 BUILD.gn
cat > BUILD.gn << 'EOF'
<此处粘贴 BUILD.gn 完整代码>
EOF

# 4. 校验
head -n 5 lcd_example.c
```
> 注意：heredoc 用单引号 'EOF'，粘贴的代码里即使有 `$` 也不会被 shell 展开；
> 粘贴后务必 `head`/`cat` 抽查首尾几行确认没被终端截断或插入乱码。

## 注意
- 中文标题不显示时，把 `lcd_example.c` 里 `lcd_show_chinese(...)` 注释掉，
  改用已验证的 `lcd_show_string(...,"TEMP/HUMI MONITOR",...)`。
- 任务栈必须用 `20480`。
- `lcd_font.h` / `picture.c` 是约 8 万字节位图数据，本方案不碰它们，保持 c2_lcd 原样即可。
