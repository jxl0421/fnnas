#!/bin/bash
# CumeBox2 LED指示灯控制脚本
# 支持：系统LED触发器和GPIO LED控制
source /etc/cumbox2/hardware.conf 2>/dev/null

# 默认配置
[ -z "$LED_STATUS_GPIO" ] && LED_STATUS_GPIO="GPIOX_6"
[ -z "$LED_DISK_GPIO" ] && LED_DISK_GPIO="GPIOX_17"

# 获取GPIO编号
get_gpio_num() {
    local gpio_name="$1"
    case "$gpio_name" in
        GPIOAO_*) echo "${gpio_name#GPIOAO_}" ;;
        GPIOX_*) echo $((18 + ${gpio_name#GPIOX_})) ;;
        AO_*) echo "${gpio_name#AO_}" ;;
        X_*) echo "$((16#${gpio_name#X_}))" ;;
        *) echo "$gpio_name" | grep -oE '[0-9]+' ;;
    esac
}

# 初始化LED GPIO
init_led_gpio() {
    local gpio_num=$1
    local gpio_path="/sys/class/gpio/gpio${gpio_num}"
    
    if [ ! -d "${gpio_path}" ]; then
        echo "${gpio_num}" > /sys/class/gpio/export 2>/dev/null
        sleep 0.3
    fi
    
    if [ -f "${gpio_path}/direction" ]; then
        echo "out" > "${gpio_path}/direction" 2>/dev/null
    fi
    
    [ -d "${gpio_path}" ]
}

# 配置LED触发器
setup_led_triggers() {
    echo "[LED] 配置LED触发器..."
    
    # 查找系统LED类设备
    for led in /sys/class/leds/*; do
        if [ -d "$led" ]; then
            led_name=$(basename "$led")
            echo "[LED] 发现LED设备: $led_name"
            
            # 状态LED - 心跳模式
            if echo "$led_name" | grep -qiE "status|power|system|heartbeat"; then
                if [ -f "$led/trigger" ]; then
                    echo "heartbeat" > "$led/trigger" 2>/dev/null
                    echo "[LED] $led_name 设置为心跳模式"
                fi
            fi
            
            # 磁盘LED - mmc0活动
            if echo "$led_name" | grep -qiE "disk|mmc|sd|activity"; then
                if [ -f "$led/trigger" ]; then
                    echo "mmc0" > "$led/trigger" 2>/dev/null || \
                    echo "disk-activity" > "$led/trigger" 2>/dev/null || \
                    echo "timer" > "$led/trigger" 2>/dev/null
                    echo "[LED] $led_name 设置为磁盘活动模式"
                fi
            fi
        fi
    done
}

# 使用GPIO控制LED（心跳闪烁）
run_gpio_heartbeat() {
    local gpio_num=$1
    local gpio_path="/sys/class/gpio/gpio${gpio_num}"
    
    echo "[LED] GPIO $gpio_num 心跳模式启动"
    
    while true; do
        if [ -f "${gpio_path}/value" ]; then
            echo 1 > "${gpio_path}/value" 2>/dev/null
            sleep 0.1
            echo 0 > "${gpio_path}/value" 2>/dev/null
            sleep 0.1
            echo 1 > "${gpio_path}/value" 2>/dev/null
            sleep 0.1
            echo 0 > "${gpio_path}/value" 2>/dev/null
            sleep 1.7
        else
            sleep 1
        fi
    done
}

# 使用GPIO监控磁盘活动
run_gpio_disk_activity() {
    local gpio_num=$1
    local gpio_path="/sys/class/gpio/gpio${gpio_num}"
    
    echo "[LED] GPIO $gpio_num 磁盘活动监控启动"
    
    local last_stats=""
    
    while true; do
        # 读取磁盘统计
        current_stats=$(cat /proc/diskstats 2>/dev/null | grep -E "mmcblk0|sda|nvme" | head -1)
        
        if [ -n "$current_stats" ] && [ "$current_stats" != "$last_stats" ]; then
            # 磁盘活动，点亮LED
            if [ -f "${gpio_path}/value" ]; then
                echo 1 > "${gpio_path}/value" 2>/dev/null
                sleep 0.05
                echo 0 > "${gpio_path}/value" 2>/dev/null
            fi
            last_stats="$current_stats"
        fi
        
        sleep 0.1
    done
}

# 主函数
main() {
    echo "[LED] LED控制服务启动..."
    
    # 方式1: 使用系统LED触发器（推荐）
    setup_led_triggers
    
    # 方式2: 如果系统LED不够，使用GPIO控制
    local use_gpio_status=0
    local use_gpio_disk=0
    
    # 检查是否需要GPIO状态LED
    if [ -n "$LED_STATUS_GPIO" ]; then
        status_gpio_num=$(get_gpio_num "$LED_STATUS_GPIO")
        if init_led_gpio "$status_gpio_num"; then
            use_gpio_status=1
            echo "[LED] 状态LED使用GPIO $status_gpio_num"
        fi
    fi
    
    # 检查是否需要GPIO磁盘LED
    if [ -n "$LED_DISK_GPIO" ]; then
        disk_gpio_num=$(get_gpio_num "$LED_DISK_GPIO")
        if init_led_gpio "$disk_gpio_num"; then
            use_gpio_disk=1
            echo "[LED] 磁盘LED使用GPIO $disk_gpio_num"
        fi
    fi
    
    # 如果不需要GPIO控制，退出
    if [ "$use_gpio_status" -eq 0 ] && [ "$use_gpio_disk" -eq 0 ]; then
        echo "[LED] 使用系统LED触发器，无需GPIO控制"
        exit 0
    fi
    
    # 启动GPIO LED控制
    if [ "$use_gpio_status" -eq 1 ]; then
        run_gpio_heartbeat "$status_gpio_num" &
        STATUS_PID=$!
    fi
    
    if [ "$use_gpio_disk" -eq 1 ]; then
        run_gpio_disk_activity "$disk_gpio_num" &
        DISK_PID=$!
    fi
    
    # 等待子进程
    wait
}

main
