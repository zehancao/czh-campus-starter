# TX-SMART-R 方案切换补记（2026-07-27 14:34）

> 主文档 TX-SMART-R温湿度LCD显示方法.md 当时被 IDE 占用无法写入，本文件为补充记录，
> 待主文档解锁后请将其内容合并回主文档的「方案变更」小节。

## 决定：放弃 m_app，改回 c2_lcd 集成（旧方案）

老板决定不新建 m_app 独立例程，改为直接在 c2_lcd 例程集成 SHT30。
- 改造文件：c2_lcd/lcd_example.c（覆盖）、c2_lcd/BUILD.gn（sources 加 src/sht30.c）、
  c2_lcd/include/sht30.h、c2_lcd/src/sht30.c（cp 自 c5_sht30）。
- 收尾：samples/BUILD.gn 只留 `"./c2_lcd:lcd_example"`；
  Makefile `hardware_LIBS` 加 `-llcd_example`（与 static_library 名一致）。
- 本地交付物：txsmartropenharmony_c2lcd/（已删除废弃的 txsmartropenharmony_m_app/）。
- LCD 大文件（lcd.c / lcd_font.h / picture.c / picture.h）保持 c2_lcd 原样，不碰、不手敲。

## 最终决定更正（2026-07-27）
此前补记写"放弃 m_app、改 c2_lcd 集成"，但老板在 VM 实际选了"补全 m_app"。故最终方案 = 补全 m_app 例程（详见技术文档.md 对应小节），c2_lcd 集成方案作废。
