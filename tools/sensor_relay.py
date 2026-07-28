#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
开发板温湿度光照 → Campus-Server 串口中继脚本
===========================================
作用：开发板(RK2206)固件用 printf 每秒输出 "temperature 26.50 RH 60.20 lux 123.45"，
      本脚本在常开主机上读串口，解析温湿度与光照，POST 到后端 /api/public/sensor/temphumi。

用法：
  pip install pyserial
  python sensor_relay.py --port COM3 --baud 115200 \
      --url http://服务器IP:8080/api/public/sensor/temphumi \
      --device-id rk2206-01

参数（均有默认值，可直接改下面的 DEFAULT_*）：
  --port       串口名，Windows 如 COM3，Linux 如 /dev/ttyUSB0
  --baud       波特率，需与板子固件一致（默认 115200）
  --url        后端上报接口完整地址
  --device-id  设备标识，便于以后多设备区分
  --interval   同一条数据最小上报间隔(秒)，避免刷屏（默认 2.0）
"""

import argparse
import json
import re
import sys
import time
import urllib.request
import urllib.error

DEFAULT_PORT = "COM3"
DEFAULT_BAUD = 115200
DEFAULT_URL = "http://localhost:8080/api/public/sensor/temphumi"
DEFAULT_DEVICE_ID = "rk2206-01"
DEFAULT_INTERVAL = 2.0

# 匹配板子 printf 输出：temperature 26.50 RH 60.20 lux 123.45（lux 可选）
LINE_RE = re.compile(
    r"temperature\s+([-\d.]+)\s+RH\s+([-\d.]+)(?:\s+lux\s+([-\d.]+))?",
    re.IGNORECASE,
)


def parse_line(line: str):
    m = LINE_RE.search(line)
    if not m:
        return None
    try:
        temp = float(m.group(1))
        humidity = float(m.group(2))
    except ValueError:
        return None
    lux = None
    if m.group(3):
        try:
            lux = float(m.group(3))
        except ValueError:
            lux = None
    return temp, humidity, lux


def post(url: str, device_id: str, temp: float, humidity: float, light: float | None):
    payload = {
        "temp": round(temp, 2),
        "humidity": round(humidity, 2),
        "deviceId": device_id,
    }
    if light is not None:
        payload["light"] = round(light, 2)
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.status


def main():
    ap = argparse.ArgumentParser(description="开发板温湿度串口中继")
    ap.add_argument("--port", default=DEFAULT_PORT)
    ap.add_argument("--baud", type=int, default=DEFAULT_BAUD)
    ap.add_argument("--url", default=DEFAULT_URL)
    ap.add_argument("--device-id", default=DEFAULT_DEVICE_ID)
    ap.add_argument("--interval", type=float, default=DEFAULT_INTERVAL)
    args = ap.parse_args()

    try:
        import serial
    except ImportError:
        print("[错误] 缺少 pyserial，请先执行: pip install pyserial", file=sys.stderr)
        sys.exit(1)

    print(f"[中继] 串口={args.port} 波特率={args.baud} 上报地址={args.url} 设备={args.device_id}")
    last_post = 0.0
    ser = None

    while True:
        # 连接/重连串口
        if ser is None or not ser.is_open:
            try:
                ser = serial.Serial(args.port, args.baud, timeout=1)
                print(f"[中继] 已打开串口 {args.port}")
            except Exception as e:
                print(f"[中继] 打开串口失败，2 秒后重试: {e}", file=sys.stderr)
                time.sleep(2)
                continue

        try:
            line = ser.readline().decode("utf-8", errors="ignore").strip()
        except Exception as e:
            print(f"[中继] 串口读取异常，重连: {e}", file=sys.stderr)
            try:
                ser.close()
            except Exception:
                pass
            ser = None
            time.sleep(2)
            continue

        if not line:
            continue

        parsed = parse_line(line)
        if parsed is None:
            continue  # 非温湿度行，忽略

        temp, humidity, lux = parsed
        now = time.time()
        if now - last_post < args.interval:
            continue  # 节流，避免每秒刷库

        try:
            status = post(args.url, args.device_id, temp, humidity, lux)
            last_post = now
            lux_str = f" lux={lux}" if lux is not None else ""
            print(f"[中继] 上报成功 HTTP {status}  temp={temp} humidity={humidity}{lux_str}")
        except urllib.error.HTTPError as e:
            print(f"[中继] 上报被拒 HTTP {e.code}: {e.read().decode('utf-8', 'ignore')}", file=sys.stderr)
        except Exception as e:
            print(f"[中继] 上报失败（后端不可达？）: {e}", file=sys.stderr)
            time.sleep(2)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[中继] 已停止")
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
