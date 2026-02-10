#!/bin/bash
source /etc/cumbox2/hardware.conf

# 获取GPIO编号的函数
get_gpio_num() {
    local gpio_name="$1"
    local gpio_num=""

    # 解析GPIO名称（如AO_3, X_49）
    if [[ "$gpio_name" =~ ^AO_([0-9]+)$ ]]; then
        gpio_num=${BASH_REMATCH[1]}
        echo "[风扇] 使用AO GPIO: ${gpio_num}"
    elif [[ "$gpio_name" =~ ^X_([0-9A-F]+)$ ]]; then
        # 转换十六进制
        gpio_num=$((16#${BASH_REMATCH[1]}))
        echo "[风扇] 使用X GPIO: ${gpio_num}"
    else
        # 直接使用数字
        gpio_num=$(echo "$gpio_name" | grep -oE '[0-9]+')
        echo "[风扇] 使用GPIO: ${gpio_num}"
    fi

    echo "$gpio_num"
}

# 初始化GPIO
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
        else
            echo "[风扇] GPIO ${gpio_num} 导出失败"
            return 1
        fi
    fi

    # 设置为输出模式
    echo "out" > "${gpio_path}/direction" 2>/dev/null
    echo "[风扇] GPIO ${gpio_num} 设置为输出模式"

    # 初始关闭风扇
    echo "0" > "${gpio_path}/value"
    echo "[风扇] 风扇初始关闭"

    return 0
}

# 获取CPU温度
get_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"

    if [ -f "$temp_file" ]; then
        local temp_raw=$(cat "$temp_file" 2>/dev/null)
        echo $((temp_raw / 1000))
    else
        # 尝试其他温度文件
        for i in /sys/class/thermal/thermal_zone*/temp; do
            if [ -f "$i" ]; then
                local temp_raw=$(cat "$i" 2>/dev/null)
                if [ -n "$temp_raw" ] && [ "$temp_raw" -gt 0 ]; then
                    echo $((temp_raw / 1000))
                    return
                fi
            fi
        done
        echo "0"
    fi
}

# 设置风扇状态
set_fan_state() {
    local state=$1
    local gpio_path="/sys/class/gpio/gpio${FAN_GPIO_NUM}/value"

    if [ -f "${gpio_path}" ]; then
        echo "${state}" > "${gpio_path}"
        local fan_status=$([ "$state" -eq 1 ] && echo "开启" || echo "关闭")
        echo "[风扇] 风扇${fan_status}"
    else
        echo "[风扇] GPIO设备不存在，跳过控制"
    fi
}

# 主函数
main() {
    echo "[风扇] 风扇自动控制服务启动..."

    # 获取GPIO编号
    FAN_GPIO_NUM=$(get_gpio_num "${FAN_GPIO}")

    if [ -z "${FAN_GPIO_NUM}" ]; then
        echo "[风扇] 错误：无法解析GPIO编号 ${FAN_GPIO}"
        exit 1
    fi

    # 初始化GPIO
    if ! init_gpio "${FAN_GPIO_NUM}"; then
        echo "[风扇] GPIO初始化失败，尝试重试..."
        sleep 5
        init_gpio "${FAN_GPIO_NUM}"
    fi

    # 等待系统稳定
    echo "[风扇] 等待系统稳定..."
    sleep 10

    echo "[风扇] 开始温度监控..."
    echo "[风扇] 低温阈值: ${FAN_TEMP_LOW}℃"
    echo "[风扇] 高温阈值: ${FAN_TEMP_HIGH}℃"

    # 主循环
    local last_temp=0
    local last_fan_state=-1

    while true; do
        # 获取CPU温度
        CPU_TEMP=$(get_cpu_temp)

        echo "[风扇] 当前温度: ${CPU_TEMP}℃"

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

        last_temp=${CPU_TEMP}

        # 延迟
        sleep 5
    done
}

main