#!/bin/bash
# CumeBox2 按键自定义脚本
source /etc/cumbox2/hardware.conf

echo "[按键] 按键自定义服务启动..."

# 检查evtest是否存在
if ! command -v evtest &>/dev/null; then
    echo "[按键] evtest未安装，尝试安装..."
    apt-get update -qq && apt-get install -y evtest 2>/dev/null || {
        echo "[按键] 无法安装evtest，退出"
        exit 1
    }
fi

# 检测输入设备
echo "[按键] 检测输入设备..."
for device in /dev/input/event*; do
    if [ -e "$device" ]; then
        name=$(cat /sys/class/input/${device##*/}/device/name 2>/dev/null || echo "Unknown")
        echo "[按键] 发现设备: $device - $name"
    fi
done

# GPIO按键监控（简化版）
# 实际按键功能需要根据硬件配置
echo "[按键] 等待按键事件..."

# 监控电源键（通过GPIO或input事件）
# 这里使用简化的实现，实际可能需要根据具体硬件调整

# 主循环 - 等待按键事件
while true; do
    # 检查GPIO状态（如果有GPIO按键）
    if [ -n "${KEY_POWER_GPIO}" ] && [ -d "/sys/class/gpio/gpio${KEY_POWER_GPIO}" ]; then
        power_state=$(cat /sys/class/gpio/gpio${KEY_POWER_GPIO}/value 2>/dev/null || echo "0")
        if [ "$power_state" = "0" ]; then
            echo "[按键] 检测到电源按键事件"
            # 执行电源按键动作（如关机、重启等）
            # shutdown -h now
        fi
    fi
    
    sleep 1
done
