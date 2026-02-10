#!/bin/bash
# ZRAM内存压缩配置 - 缓解1G内存压力

source /etc/cumbox2/optimization.conf

if [ "${ZRAM_ENABLED}" != "true" ]; then
    echo "[ZRAM优化] ZRAM未启用，跳过配置"
    exit 0
fi

echo "[ZRAM优化] 开始配置内存压缩..."

# 安装zram工具
if ! command -v zramctl &> /dev/null; then
    echo "[ZRAM优化] 安装zram-tools..."
    apt-get update -qq
    apt-get install -y zram-tools
fi

# 配置zram
echo "[ZRAM优化] 创建${ZRAM_SIZE}MB ZRAM设备..."

# 创建zram配置文件
cat > /etc/modprobe.d/zram.conf << 'EOF'
options zram num_devices=1
EOF

# 创建zram脚本
cat > /usr/local/bin/zram-setup.sh << 'EOZRAM'
#!/bin/bash
# ZRAM自动配置脚本

if [ ! -e /dev/zram0 ]; then
    modprobe zram
    echo lz4 > /sys/block/zram0/comp_algorithm
    echo 512M > /sys/block/zram0/disksize
    mkswap /dev/zram0
    swapon /dev/zram0 --priority 100
    echo "[ZRAM] 已启用512MB压缩swap"
fi
EOZRAM

chmod +x /usr/local/bin/zram-setup.sh

# 创建systemd服务
cat > /etc/systemd/system/zram.service << 'EOF'
[Unit]
Description=ZRAM Memory Compression
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/zram-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 启用zram服务
systemctl daemon-reload
systemctl enable zram.service
systemctl start zram.service

# 显示状态
echo "[ZRAM优化] ZRAM配置完成！"
zramctl
free -h

echo "[ZRAM优化] 压缩算法: ${ZRAM_COMP_ALG}"
echo "[ZRAM优化] 压缩大小: ${ZRAM_SIZE}MB"