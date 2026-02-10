#!/bin/bash
# 系统性能优化脚本 - 针对1G内存、低性能硬件

source /etc/cumbox2/optimization.conf

echo "[系统优化] 开始系统性能优化..."

# 1. 内核参数优化
echo "[系统优化] 优化内核参数..."
cat >> /etc/sysctl.d/99-cumbox2.conf << 'EOSYS'
# 内存管理优化
vm.swappiness=10
vm.vfs_cache_pressure=75
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.min_free_kbytes=65536

# 文件系统优化
fs.file-max=100000
fs.inotify.max_user_watches=524288

# 网络优化
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# 进程优化
kernel.pid_max=4194303
EOSYS

sysctl -p /etc/sysctl.d/99-cumbox2.conf

# 2. 禁用不必要的后台服务
echo "[系统优化] 禁用不必要的服务..."
systemctl disable snapd 2>/dev/null || true
systemctl disable snapd.seeded 2>/dev/null || true

# 3. 优化SSD（如果存在）
for disk in /sys/block/*; do
    if [ -f "${disk}/queue/rotational" ]; then
        ROTATIONAL=$(cat "${disk}/queue/rotational")
        if [ "${ROTATIONAL}" == "0" ]; then
            DISK_NAME=$(basename "${disk}")
            echo "[系统优化] 检测到SSD: ${DISK_NAME}，优化I/O调度器..."
            echo none > "${disk}/queue/scheduler"
            echo "[系统优化] ${DISK_NAME} I/O调度器设置为none"
        fi
    fi
done

# 4. 配置logrotate减少日志占用
echo "[系统优化] 优化日志轮转..."
cat > /etc/logrotate.d/cumbox2 << 'EOLOG'
/var/log/*.log {
    daily
    rotate 3
    compress
    delaycompress
    missingok
    notifempty
    size 10M
}
EOLOG

# 5. 禁用透明大页（减少内存使用）
echo "[系统优化] 禁用透明大页..."
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

echo "[系统优化] 系统性能优化完成！"

# 显示系统状态
echo ""
echo "=== 系统状态 ==="
free -h
echo ""
echo "=== I/O调度器 ==="
for disk in /sys/block/*/queue/scheduler; do
    echo "$disk: $(cat $disk)"
done
echo ""
echo "=== 内存优化 ==="
cat /proc/sys/vm/swappiness
cat /sys/kernel/mm/transparent_hugepage/enabled