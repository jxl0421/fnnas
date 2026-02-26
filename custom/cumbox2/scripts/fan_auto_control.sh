#!/bin/bash
source /etc/cumbox2/hardware.conf

# Amlogic S905X GPIO编号计算
# GPIOAO: 基地址 0, GPIOAO_0-9
# GPIOX: 基地址 18, GPIOX_0-19

# 获取GPIO编号的函数
get_gpio_num() {
    local gpio_name="$1"
    local gpio_num=""

    case "$gpio_name" in
        GPIOAO_*)
            gpio_num=${gpio_name#GPIOAO_}
            ;;
        GPIOX_*)
            gpio_num=$((18 + ${gpio_name#GPIOX_}))
            ;;
        AO_*)
            gpio_num=${gpio_name#AO_}
            ;;
        X_*)
            gpio_num=$((16#${gpio_name#X_}))
            ;;
        *)
            gpio_num=$(echo "$gpio_name" | grep -oE '[0-9]+')
            ;;
    esac

    echo "$gpio_num"
}

# 初始化GPIO - 使用sysfs方式
init_gpio() {
    local gpio_num=$1
    local gpio_path="/sys/class/gpio/gpio${gpio_num}"

    echo "[风扇] 初始化GPIO ${gpio_num}..."

    # 检查GPIO是否已导出
    if [ -d "${gpio_path}" ]; then
        echo "[风扇] GPIO ${gpio_num} 已导出"
    else
        # 导出GPIO
        echo "${gpio_num}" > /sys/class/gpio/export 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[风扇] GPIO ${gpio_num} 导出成功"
            sleep 0.5
        else
            echo "[风扇] GPIO ${gpio_num} 导出失败，可能需要root权限"
            return 1
        fi
    fi

    # 设置为输出模式
    if [ -f "${gpio_path}/direction" ]; then
        echo "out" > "${gpio_path}/direction" 2>/dev/null
        echo "[风扇] GPIO ${gpio_num} 设置为输出模式"
    fi

    # 初始关闭风扇
    if [ -f "${gpio_path}/value" ]; then
        echo "0" > "${gpio_path}/value" 2>/dev/null
        echo "[风扇] 风扇初始关闭"
    fi

    return 0
}

# 获取CPU温度
get_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"

    if [ -f "$temp_file" ]; then
        local temp_raw=$(cat "$temp_file" 2>/dev/null)
        if [ -n "$temp_raw" ] && [ "$temp_raw" -gt 0 ] 2>/dev/null; then
            echo $((temp_raw / 1000))
            return
        fi
    fi

    # 尝试其他温度文件
    for i in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$i" ]; then
            local temp_raw=$(cat "$i" 2>/dev/null)
            if [ -n "$temp_raw" ] && [ "$temp_raw" -gt 0 ] 2>/dev/null; then
                echo $((temp_raw / 1000))
                return
            fi
        fi
    done

    echo "0"
}

# 设置风扇状态
set_fan_state() {
    local state=$1
    local gpio_path="/sys/class/gpio/gpio${FAN_GPIO_NUM}/value"

    if [ -f "${gpio_path}" ]; then
        echo "${state}" > "${gpio_path}" 2>/dev/null
        if [ $? -eq 0 ]; then
            local fan_status=$([ "$state" -eq 1 ] && echo "开启" || echo "关闭")
            echo "[风扇] 风扇${fan_status}"
        else
            echo "[风扇] 设置风扇状态失败"
        fi
    else
        echo "[风扇] GPIO设备不存在，跳过控制"
    fi
}

# 主函数
main() {
    echo "[风扇] 风扇自动控制服务启动..."
    echo "[风扇] 配置: GPIO=${FAN_GPIO}, 低温阈值=${FAN_TEMP_LOW}C, 高温阈值=${FAN_TEMP_HIGH}C"

    # 获取GPIO编号
    FAN_GPIO_NUM=$(get_gpio_num "${FAN_GPIO}")

    if [ -z "${FAN_GPIO_NUM}" ]; then
        echo "[风扇] 错误：无法解析GPIO编号 ${FAN_GPIO}"
        echo "[风扇] 将以监控模式运行（不控制风扇）"
        FAN_GPIO_NUM=""
    fi

    # 初始化GPIO
    if [ -n "${FAN_GPIO_NUM}" ]; then
        for i in {1..3}; do
            if init_gpio "${FAN_GPIO_NUM}"; then
                break
            else
                echo "[风扇] GPIO初始化失败，第${i}次重试..."
                sleep 2
            fi
        done
    fi

    # 等待系统稳定
    echo "[风扇] 等待系统稳定..."
    sleep 5

    echo "[风扇] 开始温度监控..."

    # 主循环
    local last_fan_state=-1

    while true; do
        # 获取CPU温度
        CPU_TEMP=$(get_cpu_temp)
        
        if [ "$CPU_TEMP" -eq 0 ]; then
            echo "[风扇] 无法读取温度，等待..."
            sleep 5
            continue
        fi

        echo "[风扇] 当前温度: ${CPU_TEMP}C"

        # 如果GPIO不可用，只监控温度
        if [ -z "${FAN_GPIO_NUM}" ] || [ ! -f "/sys/class/gpio/gpio${FAN_GPIO_NUM}/value" ]; then
            sleep 5
            continue
        fi

        # 判断风扇状态
        if [ ${CPU_TEMP} -lt ${FAN_TEMP_LOW} ]; then
            # 温度低于低温阈值，关闭风扇
            if [ ${last_fan_state} -ne 0 ]; then
                set_fan_state 0
                last_fan_state=0
            fi
        elif [ ${CPU_TEMP} -ge ${FAN_TEMP_HIGH} ]; then
            # 温度高于高温阈值，开启风扇
            if [ ${last_fan_state} -ne 1 ]; then
                set_fan_state 1
                last_fan_state=1
            fi
        fi

        sleep 5
    done
}

main
