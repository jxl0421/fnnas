#!/bin/bash
# CumeBox2 OLED系统信息显示脚本
# 支持：Python(luma.oled) 和 Bash(framebuffer) 两种模式
source /etc/cumbox2/hardware.conf 2>/dev/null

# 默认配置
[ -z "$OLED_I2C_BUS" ] && OLED_I2C_BUS=1
[ -z "$OLED_I2C_ADDR" ] && OLED_I2C_ADDR="0x3c"
[ -z "$OLED_WIDTH" ] && OLED_WIDTH=128
[ -z "$OLED_HEIGHT" ] && OLED_HEIGHT=64

# 显示模式：auto/python/fb
DISPLAY_MODE="auto"
USE_PYTHON=0

# 检测Python和luma.oled库
check_python_oled() {
    if command -v python3 &>/dev/null; then
        if python3 -c "from luma.oled.device import ssd1306" 2>/dev/null; then
            echo "[OLED] 检测到Python + luma.oled环境"
            return 0
        fi
    fi
    return 1
}

# 检测I2C设备
check_i2c_device() {
    if [ -e "/dev/i2c-${OLED_I2C_BUS}" ]; then
        if i2cdetect -y ${OLED_I2C_BUS} 2>/dev/null | grep -q "${OLED_I2C_ADDR#0x}"; then
            echo "[OLED] I2C设备检测成功 (总线${OLED_I2C_BUS}, 地址${OLED_I2C_ADDR})"
            return 0
        fi
    fi
    return 1
}

# 检测framebuffer设备
check_framebuffer() {
    if [ -c "/dev/fb0" ]; then
        echo "[OLED] Framebuffer设备检测成功"
        return 0
    fi
    return 1
}

# Python OLED显示脚本
run_python_oled() {
    python3 << 'PYTHON_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import time
import socket

# 读取配置
try:
    i2c_bus = int(os.environ.get('OLED_I2C_BUS', '1'))
    i2c_addr = int(os.environ.get('OLED_I2C_ADDR', '0x3c'), 16)
    width = int(os.environ.get('OLED_WIDTH', '128'))
    height = int(os.environ.get('OLED_HEIGHT', '64'))
except:
    i2c_bus, i2c_addr, width, height = 1, 0x3c, 128, 64

try:
    from luma.core.interface.serial import i2c
    from luma.core.render import canvas
    from luma.oled.device import ssd1306
    
    serial = i2c(port=i2c_bus, address=i2c_addr)
    device = ssd1306(serial, width=width, height=height)
except Exception as e:
    print(f"[OLED] Python初始化失败: {e}")
    sys.exit(1)

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "No IP"

def get_temp():
    try:
        with open("/sys/class/thermal/thermal_zone0/temp") as f:
            return f"{int(int(f.read()) / 1000)}C"
    except:
        return "N/A"

def get_mem():
    try:
        with open("/proc/meminfo") as f:
            lines = f.readlines()
            total = int([l for l in lines if l.startswith("MemTotal:")][0].split()[1])
            free = int([l for l in lines if l.startswith("MemAvailable:")][0].split()[1])
            return f"{int((1 - free/total) * 100)}%"
    except:
        return "N/A"

def get_disk():
    try:
        import subprocess
        return subprocess.check_output("df -h / | grep / | awk '{print $5}'", shell=True).decode().strip()
    except:
        return "N/A"

def get_load():
    try:
        with open("/proc/loadavg") as f:
            return f.read().split()[0]
    except:
        return "N/A"

def main():
    print("[OLED] Python显示模式启动")
    while True:
        try:
            with canvas(device) as draw:
                draw.text((0, 0),  "CumeBox2 NAS", fill="white")
                draw.text((0, 16), f"IP: {get_ip()}", fill="white")
                draw.text((0, 32), f"CPU: {get_temp()}  MEM: {get_mem()}", fill="white")
                draw.text((0, 48), f"DISK: {get_disk()}  LOAD: {get_load()}", fill="white")
        except Exception as e:
            print(f"[OLED] 显示错误: {e}")
        time.sleep(2)

if __name__ == "__main__":
    main()
PYTHON_EOF
}

# Framebuffer显示
run_fb_display() {
    echo "[OLED] Framebuffer显示模式启动"
    
    while true; do
        # 获取系统信息
        IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -n1)
        [ -z "$IP" ] && IP="No IP"
        
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)"C"}')
        [ -z "$TEMP" ] && TEMP="N/A"
        
        MEM=$(free -m | grep Mem | awk '{print int($3/$2*100)"%"}')
        [ -z "$MEM" ] && MEM="N/A"
        
        DISK=$(df -h / | grep / | awk '{print $5}')
        [ -z "$DISK" ] && DISK="N/A"
        
        LOAD=$(cat /proc/loadavg | awk '{print $1}')
        [ -z "$LOAD" ] && LOAD="N/A"
        
        TIME=$(date +"%H:%M:%S")
        
        # 显示到framebuffer
        {
            echo -e "\033[2J\033[H"
            echo "CumeBox2 NAS"
            echo "IP: $IP"
            echo "CPU: $TEMP  MEM: $MEM"
            echo "DISK: $DISK  LOAD: $LOAD"
            echo "TIME: $TIME"
        } > /dev/fb0 2>/dev/null
        
        sleep 2
    done
}

# 主函数
main() {
    echo "[OLED] OLED系统信息显示服务启动..."
    echo "[OLED] 配置: I2C总线=${OLED_I2C_BUS}, 地址=${OLED_I2C_ADDR}"
    
    # 自动检测显示模式
    if [ "$DISPLAY_MODE" = "auto" ]; then
        if check_i2c_device && check_python_oled; then
            DISPLAY_MODE="python"
            USE_PYTHON=1
            echo "[OLED] 使用Python显示模式"
        elif check_framebuffer; then
            DISPLAY_MODE="fb"
            echo "[OLED] 使用Framebuffer显示模式"
        elif check_i2c_device; then
            # 尝试安装依赖
            echo "[OLED] 尝试安装Python依赖..."
            apt-get update -qq && apt-get install -y python3-luma.oled python3-pil 2>/dev/null
            if check_python_oled; then
                DISPLAY_MODE="python"
                USE_PYTHON=1
                echo "[OLED] 依赖安装成功，使用Python显示模式"
            else
                echo "[OLED] 依赖安装失败，仅监控模式"
                DISPLAY_MODE="monitor"
            fi
        else
            echo "[OLED] 未检测到显示设备，仅监控模式"
            DISPLAY_MODE="monitor"
        fi
    fi
    
    echo "[OLED] 显示模式: $DISPLAY_MODE"
    sleep 2
    
    # 启动显示
    case "$DISPLAY_MODE" in
        python)
            export OLED_I2C_BUS OLED_I2C_ADDR OLED_WIDTH OLED_HEIGHT
            run_python_oled
            ;;
        fb)
            run_fb_display
            ;;
        monitor)
            echo "[OLED] 监控模式运行..."
            while true; do
                TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)"C"}')
                echo "[OLED] 温度: $TEMP"
                sleep 5
            done
            ;;
    esac
}

main
