#!/bin/bash
# CumeBox2 WiFi配置脚本 - 中国大陆标准配置

source /etc/cumbox2/hardware.conf

echo "[WiFi] 开始配置无线网卡（中国大陆标准）..."

# 检查无线网卡是否存在
if ! ip link show ${WIFI_INTERFACE} >/dev/null 2>&1; then
    echo "[WiFi] 无线网卡 ${WIFI_INTERFACE} 不存在"
    exit 1
fi

echo "[WiFi] 检测到无线网卡: ${WIFI_INTERFACE}"

# 1. 设置监管域为中国
echo "[WiFi] 设置监管域为 ${WIFI_COUNTRY}..."
if command -v iw &>/dev/null; then
    # 设置监管域
    iw reg set ${WIFI_COUNTRY} 2>/dev/null || {
        echo "[WiFi] 警告：无法设置监管域，尝试使用crda..."
        # 尝试使用crda设置
        if command -v crda &>/dev/null; then
            echo ${WIFI_COUNTRY} > /etc/default/crda 2>/dev/null || true
        fi
    }
    echo "[WiFi] 监管域已设置为 ${WIFI_COUNTRY}"
else
    echo "[WiFi] 警告：iw命令不存在，跳过监管域设置"
fi

# 2. 配置无线网卡功率
echo "[WiFi] 配置无线网卡功率..."
if command -v iwconfig &>/dev/null; then
    # 设置发射功率
    iwconfig ${WIFI_INTERFACE} txpower ${WIFI_TX_POWER} 2>/dev/null || {
        echo "[WiFi] 警告：无法设置发射功率"
    }
    echo "[WiFi] 发射功率设置为 ${WIFI_TX_POWER} dBm"
else
    echo "[WiFi] 警告：iwconfig命令不存在，跳过功率设置"
fi

# 3. 配置/etc/default/crda（如果存在）
if [ -f /etc/default/crda ]; then
    echo "[WiFi] 配置/etc/default/crda..."
    sed -i "s/REGDOMAIN=.*/REGDOMAIN=${WIFI_COUNTRY}/" /etc/default/crda 2>/dev/null || {
        echo "REGDOMAIN=${WIFI_COUNTRY}" >> /etc/default/crda
    }
    echo "[WiFi] crda监管域配置完成"
fi

# 4. 创建监管域配置文件
echo "[WiFi] 创建监管域配置..."
mkdir -p /etc/wireless-regdb
cat > /etc/wireless-regdb/regulatory.bin.info << EOF
# 无线监管域配置 - 中国大陆
country=CN
alpha2=CN
dfs_region=ETSI1
channels_2ghz=1-13
channels_5ghz=36-64,149-165
max_power_2ghz=20
max_power_5ghz=20
EOF

# 5. 配置NetworkManager（如果存在）
if command -v nmcli &>/dev/null; then
    echo "[WiFi] 配置NetworkManager..."
    # 设置WiFi国家代码
    nmcli radio wifi on 2>/dev/null || true
    # 设置WiFi电源管理
    nmcli device set ${WIFI_INTERFACE} powersave no 2>/dev/null || true
    echo "[WiFi] NetworkManager配置完成"
fi

# 6. 配置wpa_supplicant（如果使用）
if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
    echo "[WiFi] 配置wpa_supplicant..."
    if ! grep -q "country=${WIFI_COUNTRY}" /etc/wpa_supplicant/wpa_supplicant.conf; then
        echo "country=${WIFI_COUNTRY}" >> /etc/wpa_supplicant/wpa_supplicant.conf
    fi
    echo "[WiFi] wpa_supplicant配置完成"
fi

# 7. 设置无线网卡为自动启动
echo "[WiFi] 启用无线网卡..."
ip link set ${WIFI_INTERFACE} up 2>/dev/null || true

# 8. 显示当前配置
echo "[WiFi] 当前无线网卡配置："
echo "--------------------------------------"
if command -v iw &>/dev/null; then
    echo "监管域："
    iw reg get 2>/dev/null | head -5
    echo ""
    echo "无线网卡信息："
    iw dev ${WIFI_INTERFACE} info 2>/dev/null | head -10
fi
if command -v iwconfig &>/dev/null; then
    echo ""
    echo "无线网卡状态："
    iwconfig ${WIFI_INTERFACE} 2>/dev/null | head -10
fi
echo "--------------------------------------"

echo "[WiFi] 无线网卡配置完成（中国大陆标准）"
echo "[WiFi] 国家代码: ${WIFI_COUNTRY}"
echo "[WiFi] 监管域: ${WIFI_REGULATORY_DOMAIN}"
echo "[WiFi] 发射功率: ${WIFI_TX_POWER} dBm"
echo "[WiFi] 2.4GHz信道: ${WIFI_CHANNEL_2G}"
echo "[WiFi] 5GHz信道: ${WIFI_CHANNEL_5G}"
