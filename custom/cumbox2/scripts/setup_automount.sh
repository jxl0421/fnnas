#!/bin/bash
# 外挂设备自动挂载脚本

source /etc/cumbox2/optimization.conf

if [ "${AUTO_MOUNT_ENABLED}" != "true" ]; then
    echo "[自动挂载] 自动挂载未启用，跳过配置"
    exit 0
fi

echo "[自动挂载] 配置外挂设备自动挂载..."

# 安装udisks2和依赖
apt-get update -qq
apt-get install -y udisks2 udiskie

# 创建挂载点目录
mkdir -p "${AUTO_MOUNT_TARGET}"
mkdir -p "${AUTO_MOUNT_TARGET}/usb"
mkdir -p "${AUTO_MOUNT_TARGET}/sata"
mkdir -p "${AUTO_MOUNT_TARGET}/nvme"

# 创建自动挂载规则
cat > /etc/udev/rules.d/99-automount.rules << 'EOUDEV'
# USB设备自动挂载
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", ENV{ID_PATH}=="*-usb-*", RUN+="/usr/local/bin/automount-usb %k"

# SATA设备自动挂载
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", ENV{ID_PATH}=="*-sata-*", RUN+="/usr/local/bin/automount-sata %k"

# NVMe设备自动挂载
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", ENV{ID_PATH}=="*-nvme-*", RUN+="/usr/local/bin/automount-nvme %k"
EOUDEV

# 创建USB挂载脚本
cat > /usr/local/bin/automount-usb.sh << 'EOUSB'
#!/bin/bash
DEVICE="/dev/$1"
MOUNT_POINT="/mnt/storage/usb"

if [ ! -b "${DEVICE}" ]; then
    exit 0
fi

# 检查设备是否已经挂载
if mount | grep -q "${DEVICE}"; then
    exit 0
fi

# 创建挂载点
mkdir -p "${MOUNT_POINT}"

# 检查文件系统类型
FSTYPE=$(lsblk -no FSTYPE "${DEVICE}")
if [ -z "${FSTYPE}" ]; then
    exit 0
fi

# 挂载设备
mount -o rw,nosuid,nodev,noexec,relatime "${DEVICE}" "${MOUNT_POINT}"
logger "已挂载USB设备: ${DEVICE} -> ${MOUNT_POINT}"
EOUSB

chmod +x /usr/local/bin/automount-usb.sh

# 创建SATA挂载脚本
cat > /usr/local/bin/automount-sata.sh << 'EOSATA'
#!/bin/bash
DEVICE="/dev/$1"
MOUNT_POINT="/mnt/storage/sata"

if [ ! -b "${DEVICE}" ]; then
    exit 0
fi

if mount | grep -q "${DEVICE}"; then
    exit 0
fi

mkdir -p "${MOUNT_POINT}"

FSTYPE=$(lsblk -no FSTYPE "${DEVICE}")
if [ -z "${FSTYPE}" ]; then
    exit 0
fi

# 检测是否为SSD，如果是SSD则创建缓存
IS_SSD=$(cat /sys/block/$(basename ${DEVICE})/queue/rotational 2>/dev/null || echo "1")
if [ "${IS_SSD}" == "0" ]; then
    # SSD设备，可以配置缓存
    MOUNT_POINT="/mnt/storage/ssd"
fi

mount -o rw,nosuid,nodev,noexec,relatime "${DEVICE}" "${MOUNT_POINT}"
logger "已挂载SATA设备: ${DEVICE} -> ${MOUNT_POINT}"
EOSATA

chmod +x /usr/local/bin/automount-sata.sh

# 创建NVMe挂载脚本
cat > /usr/local/bin/automount-nvme.sh << 'EONVME'
#!/bin/bash
DEVICE="/dev/$1"
MOUNT_POINT="/mnt/storage/nvme"

if [ ! -b "${DEVICE}" ]; then
    exit 0
fi

if mount | grep -q "${DEVICE}"; then
    exit 0
fi

mkdir -p "${MOUNT_POINT}"

FSTYPE=$(lsblk -no FSTYPE "${DEVICE}")
if [ -z "${FSTYPE}" ]; then
    exit 0
fi

mount -o rw,nosuid,nodev,noexec,relatime "${DEVICE}" "${MOUNT_POINT}"
logger "已挂载NVMe设备: ${DEVICE} -> ${MOUNT_POINT}"
EONVME

chmod +x /usr/local/bin/automount-nvme.sh

# 重载udev规则
udevadm control --reload-rules
udevadm trigger

echo "[自动挂载] 自动挂载配置完成！"
echo "[自动挂载] 挂载点：${AUTO_MOUNT_TARGET}"
echo "[自动挂载] 支持设备类型：USB, SATA, NVMe"