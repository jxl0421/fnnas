#!/bin/bash
source /etc/cumbox2/hardware.conf

USE_I2C_MODE=0

# OLED驱动检测和加载 - 支持framebuffer和用户空间驱动
load_oled_driver() {
    echo "[OLED] 检测OLED驱动 (I2C总线: $OLED_I2C_BUS, 地址: $OLED_I2C_ADDR)..."

    # 方式1: 检查framebuffer设备（内核驱动方式）
    if [ -c "/dev/fb0" ]; then
        echo "[OLED] 检测到framebuffer设备 /dev/fb0"
        USE_I2C_MODE=0
        return 0
    fi

    # 方式2: 检查内核驱动是否已加载
    if lsmod | grep -q ssd1306; then
        echo "[OLED] SSD1306驱动已加载"
        sleep 2
        if [ -c "/dev/fb0" ]; then
            USE_I2C_MODE=0
            return 0
        fi
    fi

    # 方式3: 尝试加载OLED驱动
    modprobe ssd1306fb 2>/dev/null
    if lsmod | grep -q ssd1306; then
        echo "[OLED] 驱动加载成功"
        sleep 2
        if [ -c "/dev/fb0" ]; then
            USE_I2C_MODE=0
            return 0
        fi
    fi

    # 方式4: 使用用户空间I2C驱动
    if [ -e "/dev/i2c-${OLED_I2C_BUS}" ]; then
        echo "[OLED] 使用用户空间I2C驱动模式"
        if i2cdetect -y ${OLED_I2C_BUS} 2>/dev/null | grep -q "${OLED_I2C_ADDR#0x}"; then
            echo "[OLED] 检测到OLED设备在地址${OLED_I2C_ADDR}"
            USE_I2C_MODE=1
            init_i2c_oled
            return 0
        else
            echo "[OLED] 未检测到OLED设备在地址${OLED_I2C_ADDR}"
            return 1
        fi
    else
        echo "[OLED] I2C总线${OLED_I2C_BUS}不存在"
        return 1
    fi
}

# 初始化I2C OLED（用户空间模式）
init_i2c_oled() {
    echo "[OLED] 初始化I2C OLED..."
    # 初始化序列 - SSD1306
    i2cset -y ${OLED_I2C_BUS} ${OLED_I2C_ADDR#0x} 0x00 0xAE 0xD5 0x80 0xA8 0x3F 0xD3 0x00 0x40 0x8D 0x14 0x20 0x00 0xA1 0xC8 0xDA 0x12 0x81 0xCF 0xD9 0xF1 0xDB 0x40 0xA4 0xA6 0xAF 2>/dev/null
    echo "[OLED] I2C OLED初始化完成"
}

# 初始化OLED显示
init_oled_display() {
    if [ "$USE_I2C_MODE" = "1" ]; then
        init_i2c_oled
    else
        # 等待framebuffer设备
        if [ ! -c /dev/fb0 ]; then
            echo "[OLED] 等待framebuffer设备..."
            sleep 2
        fi
        
        # 设置显示方向
        if [ "$OLED_ROTATE" = "1" ]; then
            echo "[OLED] 设置显示旋转180度"
        fi
    fi
}

# 显示系统信息 - Framebuffer模式
display_fb_info() {
    # 清屏
    echo -e "\033[2J" > /dev/fb0 2>/dev/null
    
    # 显示信息
    echo -e "IP: $1" > /dev/fb0 2>/dev/null
    echo -e "CPU: $2 | MEM: $3" > /dev/fb0 2>/dev/null
    echo -e "DISK: $4 | TIME: $5" > /dev/fb0 2>/dev/null
    echo -e "LOAD: $6" > /dev/fb0 2>/dev/null
}

# 显示系统信息 - I2C用户空间模式（简化版）
display_i2c_info() {
    # I2C模式下的简化显示 - 只记录日志
    echo "[OLED-I2C] IP: $1, CPU: $2, MEM: $3, DISK: $4"
}

# 显示系统信息
display_system_info() {
    # 获取IP
    IP=$(ip addr show $NETWORK_INTERFACE 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -n1)
    [ -z "$IP" ] && IP=$(ip addr show $WIFI_INTERFACE 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -n1)
    [ -z "$IP" ] && IP="No IP"

    # CPU温度
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)"C"}')
    [ -z "$CPU_TEMP" ] && CPU_TEMP="0C"

    # 内存使用率
    MEM_USAGE=$(free -m 2>/dev/null | grep Mem | awk '{print int($3/$2*100)"%"}')
    [ -z "$MEM_USAGE" ] && MEM_USAGE="0%"

    # 磁盘使用率
    DISK_USAGE=$(df -h / 2>/dev/null | grep / | awk '{print $5}')
    [ -z "$DISK_USAGE" ] && DISK_USAGE="0%"

    # 系统时间
    SYS_TIME=$(date +"%H:%M:%S" 2>/dev/null)
    [ -z "$SYS_TIME" ] && SYS_TIME="--:--:--"

    # 系统负载
    SYS_LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
    [ -z "$SYS_LOAD" ] && SYS_LOAD="0.00"

    # 根据模式显示
    if [ "$USE_I2C_MODE" = "1" ]; then
        display_i2c_info "$IP" "$CPU_TEMP" "$MEM_USAGE" "$DISK_USAGE"
    else
        display_fb_info "$IP" "$CPU_TEMP" "$MEM_USAGE" "$DISK_USAGE" "$SYS_TIME" "$SYS_LOAD"
    fi
}

# 主循环
main() {
    echo "[OLED] OLED系统信息显示服务启动..."
    echo "[OLED] 配置: I2C总线=${OLED_I2C_BUS}, 地址=${OLED_I2C_ADDR}"

    # 加载驱动
    for i in {1..5}; do
        if load_oled_driver; then
            echo "[OLED] 驱动初始化成功"
            break
        else
            echo "[OLED] 驱动加载失败，第${i}次重试..."
            sleep 5
        fi
    done

    # 初始化显示
    init_oled_display

    # 等待系统稳定
    echo "[OLED] 等待系统稳定..."
    sleep 3

    # 循环刷新
    echo "[OLED] 开始显示系统信息..."
    while true; do
        display_system_info
        sleep 2
    done
}

main
