#!/bin/bash
source /etc/cumbox2/hardware.conf

# OLED驱动检测和加载
load_oled_driver() {
    echo "[OLED] 检测OLED驱动..."

    # 检查是否已加载
    if lsmod | grep -q ssd1306; then
        echo "[OLED] 驱动已加载"
        return 0
    fi

    # 尝试加载OLED驱动
    modprobe ssd1306fb 2>/dev/null

    # 检查是否加载成功
    if lsmod | grep -q ssd1306; then
        echo "[OLED] 驱动加载成功"
        sleep 2
        return 0
    else
        echo "[OLED] 驱动加载失败，尝试其他方式..."

        # 尝试i2c设备检测
        if [ -d "/dev/i2c-${OLED_I2C_BUS}" ]; then
            echo "[OLED] 检测到I2C总线${OLED_I2C_BUS}"

            # 检查设备是否存在
            if i2cdetect -y ${OLED_I2C_BUS} 2>/dev/null | grep -q "3c"; then
                echo "[OLED] 检测到OLED设备在地址0x3c"
                return 0
            else
                echo "[OLED] 未检测到OLED设备"
                return 1
            fi
        else
            echo "[OLED] I2C总线${OLED_I2C_BUS}不存在"
            return 1
        fi
    fi
}

# 显示函数
display_system_info() {
    # 等待framebuffer设备
    if [ ! -c /dev/fb0 ]; then
        echo "[OLED] 等待framebuffer设备..."
        return 1
    fi

    # 获取IP
    IP=$(ip addr show eth0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
    [ -z "$IP" ] && IP=$(ip addr show wlan0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
    [ -z "$IP" ] && IP="No Network"

    # CPU温度
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)"℃"}')
    [ -z "$CPU_TEMP" ] && CPU_TEMP="0℃"

    # 内存使用率
    MEM_USAGE=$(free -m | grep Mem | awk '{print int($3/$2*100)"%"}')

    # 磁盘使用率
    DISK_USAGE=$(df -h / | grep / | awk '{print $5}')

    # 系统时间
    SYS_TIME=$(date +"%H:%M:%S")

    # 清屏+显示
    echo -e "\033[2J" > /dev/fb0 2>/dev/null
    echo -e "IP: $IP" > /dev/fb0 2>/dev/null
    echo -e "CPU: $CPU_TEMP | MEM: $MEM_USAGE" > /dev/fb0 2>/dev/null
    echo -e "DISK: $DISK_USAGE | TIME: $SYS_TIME" > /dev/fb0 2>/dev/null
}

# 主循环
main() {
    echo "[OLED] OLED系统信息显示服务启动..."

    # 加载驱动
    if ! load_oled_driver; then
        echo "[OLED] OLED驱动加载失败，等待重试..."
        sleep 10
        load_oled_driver
    fi

    # 等待网络连接
    echo "[OLED] 等待网络连接..."
    sleep 5

    # 循环刷新
    while true; do
        display_system_info
        sleep 2
    done
}

main