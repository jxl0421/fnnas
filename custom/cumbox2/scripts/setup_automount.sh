#!/bin/bash
# 外挂设备自动挂载脚本（保持与原项目兼容）
# 使用标准udisks2自动挂载机制

source /etc/cumbox2/optimization.conf

if [ "${AUTO_MOUNT_ENABLED}" != "true" ]; then
    echo "[自动挂载] 自动挂载未启用，跳过配置"
    exit 0
fi

echo "[自动挂载] 配置标准自动挂载（兼容原项目）..."

# 安装udisks2（标准组件）
if ! dpkg -l | grep -q udisks2; then
    echo "[自动挂载] 安装udisks2..."
    apt-get update -qq
    apt-get install -y udisks2
fi

# 使用GNOME磁盘挂载方式（最标准）
if ! dpkg -l | grep -q udiskie; then
    echo "[自动挂载] 安装udiskie（自动挂载助手）..."
    apt-get install -y udiskie
fi

# 创建标准systemd用户服务（用于用户会话）
cat > /etc/systemd/system/udiskie.service << 'EOU'
[Unit]
Description=udiskie automount daemon
After=graphical-session.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/udiskie --tray --automount --notify
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOU

# 确保udisks2服务启用
systemctl daemon-reload
systemctl enable udisks2 2>/dev/null || true

# 不自动启用udiskie服务（需要图形界面）
# 可以在需要时手动启用：systemctl --user start udiskie

# 添加标准桌面用户到plugdev组（标准权限）
for user in $(getent passwd {1000..6000} | cut -d: -f1); do
    usermod -aG plugdev,disk "$user" 2>/dev/null || true
done

echo "[自动挂载] 自动挂载配置完成！"
echo "[自动挂载] 挂载位置：/media/（根据设备标签或UUID自动创建）"
echo "[自动挂载] 使用udisks2标准机制，与原项目兼容"
echo ""
echo "手动挂载示例："
echo "  udisksctl mount -b /dev/sdX1"
echo "  udisksctl unmount -b /dev/sdX1"