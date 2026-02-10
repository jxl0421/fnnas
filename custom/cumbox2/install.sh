#!/bin/bash
# CumeBox2 安装脚本
# 针对1G内存、8GB存储优化配置

set -e

echo "======================================"
echo "  CumeBox2 硬件适配安装脚本"
echo "  针对1G内存、8GB存储优化"
echo "======================================"
echo ""

# 1. 创建目录
echo "[步骤 1/7] 创建必要目录..."
mkdir -p /usr/local/cumbox2/scripts
mkdir -p /etc/cumbox2
mkdir -p /media
mkdir -p /var/log/cumbox2
echo "[完成] 目录创建完成"
echo ""

# 2. 复制配置文件
echo "[步骤 2/7] 安装配置文件..."
cp /custom/cumbox2/config/hardware.conf /etc/cumbox2/
if [ -f /custom/cumbox2/config/optimization.conf ]; then
    cp /custom/cumbox2/config/optimization.conf /etc/cumbox2/
fi
echo "[完成] 配置文件安装完成"
echo ""

# 3. 复制脚本文件
echo "[步骤 3/7] 安装脚本文件..."
cp /custom/cumbox2/scripts/*.sh /usr/local/cumbox2/scripts/
echo "[完成] 脚本文件安装完成"
echo ""

# 4. 安装systemd服务
    echo "[步骤 4/7] 安装systemd服务..."
    cp /custom/cumbox2/systemd/*.service /lib/systemd/system/
    echo "[完成] systemd服务安装完成"
    echo ""

# 5. 安装设备树补丁
    echo "[步骤 5/7] 安装设备树补丁..."
    if [ -d "/custom/cumbox2/patch" ]; then
        cp /custom/cumbox2/patch/*.patch /usr/share/ophub/patches/ 2>/dev/null || true
        echo "[完成] 设备树补丁安装完成"
    else
        echo "[警告] 设备树补丁目录不存在，跳过..."
    fi
    echo ""

# 5. 添加执行权限
echo "[步骤 5/7] 设置执行权限..."
chmod +x /usr/local/cumbox2/scripts/*.sh
echo "[完成] 执行权限设置完成"
echo ""

# 6. 优化系统配置
echo "[步骤 6/7] 优化系统配置..."

# 6.1 配置Swap（针对1G内存）
echo "  [6.1] 配置Swap优化..."
if [ -f /usr/local/cumbox2/scripts/setup_swap.sh ]; then
    /usr/local/cumbox2/scripts/setup_swap.sh
fi

# 6.2 配置ZRAM内存压缩
echo "  [6.2] 配置ZRAM内存压缩..."
if [ -f /usr/local/cumbox2/scripts/setup_zram.sh ]; then
    /usr/local/cumbox2/scripts/setup_zram.sh
fi

# 6.3 配置自动挂载
echo "  [6.3] 配置外挂设备自动挂载..."
if [ -f /usr/local/cumbox2/scripts/setup_automount.sh ]; then
    /usr/local/cumbox2/scripts/setup_automount.sh
fi

# 6.4 系统性能优化
echo "  [6.4] 执行系统性能优化..."
if [ -f /usr/local/cumbox2/scripts/optimize_system.sh ]; then
    /usr/local/cumbox2/scripts/optimize_system.sh
fi

echo "[完成] 系统优化完成"
echo ""

# 7. 启用硬件相关服务
echo "[步骤 7/7] 启用CumeBox2硬件服务..."
systemctl daemon-reload

# 复制检查脚本
if [ -f /custom/cumbox2/scripts/check_services.sh ]; then
    cp /custom/cumbox2/scripts/check_services.sh /usr/local/cumbox2/scripts/
    chmod +x /usr/local/cumbox2/scripts/check_services.sh
    echo "  ✓ 服务检查脚本已安装"
fi

# 启用OLED显示服务
if [ -f /lib/systemd/system/cumbox2-oled.service ]; then
    systemctl enable cumbox2-oled.service
    echo "  ✓ OLED显示服务已启用"
fi

# 启用风扇控制服务
if [ -f /lib/systemd/system/cumbox2-fan.service ]; then
    systemctl enable cumbox2-fan.service
    echo "  ✓ 风扇控制服务已启用"
fi

# 启用按键服务
if [ -f /lib/systemd/system/cumbox2-key.service ]; then
    systemctl enable cumbox2-key.service
    echo "  ✓ 按键服务已启用"
fi

# 启用ZRAM服务
if [ -f /etc/systemd/system/zram.service ]; then
    systemctl enable zram.service
    echo "  ✓ ZRAM内存压缩服务已启用"
fi

echo "[完成] 硬件服务启用完成"
echo ""

# 8. 安装依赖包
echo "[安装] 安装系统依赖..."
apt-get update -qq
apt-get install -y i2c-tools evtest udisks2 udiskie zram-tools
echo "[完成] 依赖包安装完成"
echo ""

# 9. 启动服务并检查状态
echo "[检查] 启动硬件服务..."

# 启动OLED服务
if systemctl is-enabled cumbox2-oled.service 2>/dev/null; then
    echo "  启动OLED服务..."
    systemctl start cumbox2-oled.service
    sleep 3
    if systemctl is-active cumbox2-oled.service >/dev/null 2>&1; then
        echo "  ✓ OLED服务运行正常"
    else
        echo "  ✗ OLED服务启动失败，将在后台自动重试"
    fi
fi

# 启动风扇服务
if systemctl is-enabled cumbox2-fan.service 2>/dev/null; then
    echo "  启动风扇服务..."
    systemctl start cumbox2-fan.service
    sleep 2
    if systemctl is-active cumbox2-fan.service >/dev/null 2>&1; then
        echo "  ✓ 风扇服务运行正常"
    else
        echo "  ✗ 风扇服务启动失败，将在后台自动重试"
    fi
fi

# 启动按键服务
if systemctl is-enabled cumbox2-key.service 2>/dev/null; then
    echo "  启动按键服务..."
    systemctl start cumbox2-key.service
    sleep 2
    if systemctl is-active cumbox2-key.service >/dev/null 2>&1; then
        echo "  ✓ 按键服务运行正常"
    else
        echo "  ✗ 按键服务启动失败，将在后台自动重试"
    fi
fi

echo ""

# 10. 显示系统信息
echo "======================================"
echo "  CumeBox2 安装完成！"
echo "======================================"
echo ""
echo "系统配置："
free -h
echo ""
echo "存储使用："
df -h / | tail -1
echo ""
echo "服务状态："
systemctl is-active cumbox2-oled.service 2>/dev/null && echo "  ✓ OLED显示服务" || echo "  ○ OLED显示服务（重试中）"
systemctl is-active cumbox2-fan.service 2>/dev/null && echo "  ✓ 风扇控制服务" || echo "  ○ 风扇控制服务（重试中）"
systemctl is-active cumbox2-key.service 2>/dev/null && echo "  ✓ 按键服务" || echo "  ○ 按键服务（重试中）"
systemctl is-active zram.service 2>/dev/null && echo "  ✓ ZRAM内存压缩" || echo "  ○ ZRAM内存压缩"
echo ""
echo "优化特性："
echo "  ✓ Swap优化（2GB）"
echo "  ✓ ZRAM内存压缩（512MB）"
echo "  ✓ 外挂设备自动挂载（/media/，标准udisks2）"
echo "  ✓ 系统性能优化"
echo "  ✓ OLED显示"
echo "  ✓ 风扇自动控制"
echo "  ✓ 按键自定义"
echo ""
echo "======================================"
echo "  安装完成，系统将自动重启服务"
echo "======================================"
echo ""

# 创建启动信息
cat > /etc/motd.d/cumbox2 << 'EOM'
=================================================================
  CumeBox2 硬件适配已安装
=================================================================

系统优化：
  • Swap: 2GB
  • ZRAM: 512MB压缩内存
  • 外挂设备: 自动挂载到/media/

硬件服务：
  • OLED: 自动显示系统信息
  • 风扇: 根据温度自动调节
  • 按键: 自定义功能

查看日志：journalctl -u cumbox2-* -f
=================================================================
EOM

echo "安装完成！硬件服务将在后台自动启动和重试。"
echo ""
echo "常用命令："
echo "  检查服务状态: /usr/local/cumbox2/scripts/check_services.sh"
echo "  查看服务状态: systemctl status cumbox2-oled cumbox2-fan cumbox2-key"
echo "  查看服务日志: journalctl -u cumbox2-* -f"
echo ""
echo "服务会在启动失败后自动重试（每10秒一次），"
echo "无需手动干预，等待1-2分钟即可正常运行。"