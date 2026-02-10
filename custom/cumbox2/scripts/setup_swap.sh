#!/bin/bash
# Swap优化脚本 - 针对1G内存

source /etc/cumbox2/optimization.conf

echo "[Swap优化] 开始配置..."

# 检查是否已有swap
if [ -f "${SWAP_PATH}" ]; then
    echo "[Swap优化] 检测到现有swap文件，正在移除..."
    swapoff "${SWAP_PATH}" 2>/dev/null
    rm -f "${SWAP_PATH}"
fi

# 创建swap文件
echo "[Swap优化] 创建${SWAP_SIZE}MB swap文件..."
dd if=/dev/zero of="${SWAP_PATH}" bs=1M count="${SWAP_SIZE}" status=progress
chmod 600 "${SWAP_PATH}"
mkswap "${SWAP_PATH}"

# 启用swap
echo "[Swap优化] 启用swap..."
swapon "${SWAP_PATH}"

# 设置开机自动挂载
if ! grep -q "${SWAP_PATH}" /etc/fstab; then
    echo "${SWAP_PATH} none swap sw 0 0" >> /etc/fstab
fi

# 设置vm参数
echo "[Swap优化] 调整vm参数..."
sysctl vm.swappiness=${VM_SWAPPINESS}
sysctl vm.vfs_cache_pressure=${VM_VFS_CACHE_PRESSURE}
sysctl vm.dirty_ratio=${VM_DIRTY_RATIO}
sysctl vm.dirty_background_ratio=${VM_DIRTY_BACKGROUND_RATIO}

# 持久化vm参数
echo "vm.swappiness=${VM_SWAPPINESS}" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=${VM_VFS_CACHE_PRESSURE}" >> /etc/sysctl.conf
echo "vm.dirty_ratio=${VM_DIRTY_RATIO}" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio=${VM_DIRTY_BACKGROUND_RATIO}" >> /etc/sysctl.conf

# 显示swap状态
echo "[Swap优化] Swap配置完成！"
free -h
swapon --show

echo "[Swap优化] Swap大小: ${SWAP_SIZE}MB, Swappiness: ${VM_SWAPPINESS}"