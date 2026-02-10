#!/bin/bash
# CumeBox2 服务状态检查脚本

echo "======================================"
echo "  CumeBox2 服务状态检查"
echo "======================================"
echo ""

# 检查OLED服务
echo "[1] 检查OLED显示服务..."
if systemctl is-enabled cumbox2-oled.service 2>/dev/null; then
    echo "  状态: 已启用"
    if systemctl is-active cumbox2-oled.service >/dev/null 2>&1; then
        echo "  运行: ✓ 正常运行"
    else
        echo "  运行: ✗ 未运行（正在重试）"
    fi
    echo ""
    echo "  最近日志（最近10行）:"
    journalctl -u cumbox2-oled -n 10 --no-pager | tail -n 10
else
    echo "  状态: ✗ 未启用"
fi
echo ""

# 检查风扇服务
echo "[2] 检查风扇控制服务..."
if systemctl is-enabled cumbox2-fan.service 2>/dev/null; then
    echo "  状态: 已启用"
    if systemctl is-active cumbox2-fan.service >/dev/null 2>&1; then
        echo "  运行: ✓ 正常运行"
    else
        echo "  运行: ✗ 未运行（正在重试）"
    fi
    echo ""
    echo "  最近日志（最近10行）:"
    journalctl -u cumbox2-fan -n 10 --no-pager | tail -n 10
else
    echo "  状态: ✗ 未启用"
fi
echo ""

# 检查按键服务
echo "[3] 检查按键服务..."
if systemctl is-enabled cumbox2-key.service 2>/dev/null; then
    echo "  状态: 已启用"
    if systemctl is-active cumbox2-key.service >/dev/null 2>&1; then
        echo "  运行: ✓ 正常运行"
    else
        echo "  运行: ✗ 未运行（正在重试）"
    fi
    echo ""
    echo "  最近日志（最近10行）:"
    journalctl -u cumbox2-key -n 10 --no-pager | tail -n 10
else
    echo "  状态: ✗ 未启用"
fi
echo ""

# 检查ZRAM服务
echo "[4] 检查ZRAM内存压缩服务..."
if systemctl is-enabled zram.service 2>/dev/null; then
    echo "  状态: 已启用"
    if systemctl is-active zram.service >/dev/null 2>&1; then
        echo "  运行: ✓ 正常运行"
        echo ""
        echo "  ZRAM状态:"
        zramctl
    else
        echo "  运行: ✗ 未运行"
    fi
else
    echo "  状态: ✗ 未启用"
fi
echo ""

# 检查内存状态
echo "[5] 内存状态:"
free -h
echo ""

# 检查Swap状态
echo "[6] Swap状态:"
swapon --show
echo ""

# 检查挂载状态
echo "[7] 外挂设备挂载状态:"
df -h | grep /media/ || echo "  无外挂设备挂载"
echo ""

# 检查I2C设备
echo "[8] I2C设备检测:"
if command -v i2cdetect &> /dev/null; then
    i2cdetect -y 0 2>/dev/null || echo "  I2C总线0未检测到设备"
    i2cdetect -y 1 2>/dev/null || echo "  I2C总线1未检测到设备"
else
    echo "  i2c-tools未安装"
fi
echo ""

# 检查GPIO状态
echo "[9] GPIO导出状态:"
if [ -d /sys/class/gpio ]; then
    ls /sys/class/gpio/ | grep -E '^[0-9]+$' | while read gpio; do
        echo "  GPIO $gpio: $(cat /sys/class/gpio/gpio$gpio/direction 2>/dev/null || 'N/A')"
    done
else
    echo "  GPIO未导出"
fi
echo ""

echo "======================================"
echo "  检查完成"
echo "======================================"
echo ""
echo "操作提示："
echo "  重启服务: systemctl restart cumbox2-oled"
echo "  停止服务: systemctl stop cumbox2-fan"
echo "  查看日志: journalctl -u cumbox2-* -f"
echo "  重新安装: /custom/cumbox2/install.sh"