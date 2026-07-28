@echo off
chcp 65001 >nul
title 传感器中继 (开发板 -> 后端)
echo ========================================
echo   传感器中继 - RK2206 -> Campus-Server
echo ========================================
echo.
echo 串口: COM7   波特率: 115200
echo 后端: http://127.0.0.1:8080
echo.
echo 请确认:
echo   1) Spring Boot 后端已启动
echo   2) Xshell / 串口助手等占用 COM7 的软件已关闭
echo   3) 开发板已上电并按了 RESET
echo.
echo 按任意键开始 (Ctrl+C 退出) ...
pause >nul
cd /d "%~dp0"
"C:\Users\Dell\.workbuddy\binaries\python\envs\default\Scripts\python.exe" -u sensor_relay.py --port COM7 --url http://127.0.0.1:8080/api/public/sensor/temphumi
pause