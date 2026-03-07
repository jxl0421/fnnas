#!/bin/bash
# CumeBox2 风扇自动控制脚本
# 支持：PWM模式(hwmon) 和 GPIO模式(sysfs)
source /etc/cumbox2/hardware.conf 2>/dev/null

# 默认配置
[ -z "$FAN_TEMP_LOW" ] && FAN_TEMP_LOW=50
[ -z "$FAN_TEMP_HIGH" ] && FAN_TEMP_HIGH=70

# 控制模式：auto/pwm/gpio
CONTROL_MODE="auto"
PWM_PATH=""
GPIO_NUM=""

# 检测PWM设备（hwmon方式）
detect_pwm_device() {
    # 检查hwmon下的pwm设备
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -d "$hwmon" ]; then
            if [ -f "$hwmon/pwm1" ] && [ -f "$hwmon/pwm1_enable" ]; then
                PWM_PATH="$hwmon"
                echo "[风扇] 检测到PWM设备: $PWM_PATH"
                return 0
            fi
        fi
    done
    
    # 检查特定路径（某些设备）
    if [ -f "/sys/class/hwmon/hwmon0/pwm1" ]; then
        PWM_PATH="/sys/class/hwmon/hwmon0"
        echo "[风扇] 使用默认PWM路径: $PWM_PATH"
        return 0
    fi
    
    return 1
}

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

# 初始化GPIO
init_gpio() {
    local gpio_num=$1
    local gpio_path="/sys/class/gpio/gpio${gpio_num}"
    
    if [ -d "${gpio_path}" ]; then
        echo "[风扇] GPIO ${gpio_num} 已导出"
    else
        echo "${gpio_num}" > /sys/class/gpio/export 2>/dev/null
        sleep 0.5
    fi
    
    if [ -f "${gpio_path}/direction" ]; then
        echo "out" > "${gpio_path}/direction" 2>/dev/null
    fi
    
    if [ -f "${gpio_path}/value" ]; then
        echo "0" > "${gpio_path}/value" 2>/dev/null
    fi
    
    [ -d "${gpio_path}" ]
}

# 设置PWM风扇
set_pwm_fan() {
    local speed=$1  # 0-255
    if [ -n "$PWM_PATH" ] && [ -f "$PWM_PATH/pwm1" ]; then
        echo 1 > "$PWM_PATH/pwm1_enable" 2>/dev/null
        echo "$speed" > "$PWM_PATH/pwm1" 2>/dev/null
    fi
}

# 设置GPIO风扇
set_gpio_fan() {
    local state=$1  # 0或1
    local gpio_path="/sys/class/gpio/gpio${GPIO_NUM}/value"
    if [ -f "$gpio_path" ]; then
        echo "$state" > "$gpio_path" 2>/dev/null
    fi
}

# 获取CPU温度
get_cpu_temp() {
    local temp=0
    
    # 标准路径
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    fi
    
    # 备选路径
    if [ -z "$temp" ] || [ "$temp" = "0" ]; then
        temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp 2>/dev/null)
    fi
    
    # 返回摄氏度
    echo $((temp / 1000))
}

# 主函数
main() {
    echo "[风扇] 风扇自动控制服务启动..."
    echo "[风扇] 配置: 低温阈值=${FAN_TEMP_LOW}C, 高温阈值=${FAN_TEMP_HIGH}C"
    
    # 自动检测控制模式
    if [ "$CONTROL_MODE" = "auto" ]; then
        if detect_pwm_device; then
            CONTROL_MODE="pwm"
            echo "[风扇] 使用PWM控制模式"
        elif [ -n "$FAN_GPIO" ]; then
            GPIO_NUM=$(get_gpio_num "$FAN_GPIO")
            if [ -n "$GPIO_NUM" ] && init_gpio "$GPIO_NUM"; then
                CONTROL_MODE="gpio"
                echo "[风扇] 使用GPIO控制模式 (GPIO $GPIO_NUM)"
            else
                echo "[风扇] GPIO初始化失败，仅监控温度"
                CONTROL_MODE="monitor"
            fi
        else
            echo "[风扇] 未找到控制设备，仅监控温度"
            CONTROL_MODE="monitor"
        fi
    fi
    
    echo "[风扇] 控制模式: $CONTROL_MODE"
    sleep 2
    
    # 主循环
    local last_state=-1
    
    while true; do
        TEMP=$(get_cpu_temp)
        
        if [ "$TEMP" -eq 0 ]; then
            echo "[风扇] 无法读取温度"
            sleep 5
            continue
        fi
        
        # 计算风扇状态
        local new_state=0
        if [ "$TEMP" -ge "$FAN_TEMP_HIGH" ]; then
            new_state=1
        elif [ "$TEMP" -lt "$FAN_TEMP_LOW" ]; then
            new_state=0
        else
            new_state=$last_state  # 保持当前状态（滞后）
        fi
        
        # 状态变化时执行控制
        if [ "$new_state" -ne "$last_state" ]; then
            echo "[风扇] 温度: ${TEMP}C, 状态变化: $last_state -> $new_state"
            
            case "$CONTROL_MODE" in
                pwm)
                    if [ "$new_state" -eq 1 ]; then
                        set_pwm_fan 180  # 70%转速
                        echo "[风扇] PWM风扇开启 (70%)"
                    else
                        set_pwm_fan 0
                        echo "[风扇] PWM风扇关闭"
                    fi
                    ;;
                gpio)
                    set_gpio_fan "$new_state"
                    echo "[风扇] GPIO风扇$([ "$new_state" -eq 1 ] && echo '开启' || echo '关闭')"
                    ;;
                monitor)
                    echo "[风扇] 监控模式: 温度 ${TEMP}C"
                    ;;
            esac
            
            last_state=$new_state
        fi
        
        sleep 3
    done
}

main
