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
mkdir -p /mnt/storage
mkdir -p /mnt/storage/usb
mkdir -p /mnt/storage/sata
mkdir -p /mnt/storage/nvme
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

# OLED显示服务
if [ -f /lib/systemd/system/cumbox2-oled.service ]; then
    systemctl enable cumbox2-oled.service
    echo "  - OLED显示服务已启用"
fi

# 风扇控制服务
if [ -f /lib/systemd/system/cumbox2-fan.service ]; then
    systemctl enable cumbox2-fan.service
    echo "  - 风扇控制服务已启用"
fi

# 按键服务
if [ -f /lib/systemd/system/cumbox2-key.service ]; then
    systemctl enable cumbox2-key.service
    echo "  - 按键服务已启用"
fi

# ZRAM服务
if [ -f /etc/systemd/system/zram.service ]; then
    systemctl enable zram.service
    echo "  - ZRAM内存压缩服务已启用"
fi

echo "[完成] 硬件服务启用完成"
echo ""

# 8. 安装依赖包
echo "[安装] 安装系统依赖..."
apt-get update -qq
apt-get install -y i2c-tools evtest udisks2 udiskie zram-tools
echo "[完成] 依赖包安装完成"
echo ""

# 9. 显示系统信息
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
echo "挂载点："
df -h | grep /mnt/storage || echo "  无外挂设备"
echo ""
echo "优化特性："
echo "  ✓ Swap优化（2GB）"
echo "  ✓ ZRAM内存压缩（512MB）"
echo "  ✓ 外挂设备自动挂载"
echo "  ✓ 系统性能优化"
echo "  ✓ OLED显示"
echo "  ✓ 风扇自动控制"
echo "  ✓ 按键自定义"
echo ""
echo "======================================"
echo "  系统将在5秒后重启以应用所有配置"
echo "======================================"

# 创建重启提示
echo "系统安装完成，将在重启后完全生效" > /etc/motd.d/cumbox2

# 自动重启（可选，如果不想自动重启可注释掉）
# reboot