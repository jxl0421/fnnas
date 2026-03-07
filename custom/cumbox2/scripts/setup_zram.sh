#!/bin/bash
# ZRAM内存压缩配置 - 缓解1G内存压力
# 由zram.service调用

source /etc/cumbox2/optimization.conf 2>/dev/null

# 默认配置
ZRAM_SIZE="${ZRAM_SIZE:-512}"
ZRAM_COMP_ALG="${ZRAM_COMP_ALG:-lz4}"

echo "[ZRAM] 开始配置内存压缩..."

# 检查zram模块
if ! lsmod | grep -q zram; then
    echo "[ZRAM] 加载zram模块..."
    modprobe zram num_devices=1 || {
        echo "[ZRAM] 无法加载zram模块"
        exit 1
    }
fi

# 检查zram设备是否已配置
if [ -e /dev/zram0 ] && swapon --show | grep -q zram0; then
    echo "[ZRAM] ZRAM已启用，跳过配置"
    zramctl
    exit 0
fi

# 配置zram设备
echo "[ZRAM] 创建${ZRAM_SIZE}MB ZRAM设备..."

# 设置压缩算法
if [ -f /sys/block/zram0/comp_algorithm ]; then
    echo ${ZRAM_COMP_ALG} > /sys/block/zram0/comp_algorithm 2>/dev/null || \
    echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null
    echo "[ZRAM] 压缩算法: $(cat /sys/block/zram0/comp_algorithm)"
fi

# 设置磁盘大小
echo "${ZRAM_SIZE}M" > /sys/block/zram0/disksize 2>/dev/null || {
    echo "[ZRAM] 无法设置磁盘大小"
    exit 1
}

# 创建swap
mkswap /dev/zram0 2>/dev/null || {
    echo "[ZRAM] 无法创建swap"
    exit 1
}

# 启用swap
swapon /dev/zram0 --priority 100 2>/dev/null || {
    echo "[ZRAM] 无法启用swap"
    exit 1
}

# 创建配置文件以便后续使用
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/zram.conf << 'EOF'
options zram num_devices=1
EOF

# 显示状态
echo "[ZRAM] ZRAM配置完成！"
zramctl
free -h

echo "[ZRAM] 当前swap状态："
swapon --show
