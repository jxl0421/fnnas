# CumeBox2 无线网卡中国大陆配置说明

## 配置概述

CumeBox2固件已按照中国大陆无线管理法规配置无线网卡，确保符合中国无线电管理规定。

## 配置标准

### 国家代码和监管域
- **国家代码**：CN（中国）
- **监管域**：CN
- **DFS区域**：ETSI1

### 频段和信道配置

#### 2.4GHz频段（802.11b/g/n）
- **可用信道**：1-13
- **最大功率**：20dBm（100mW）
- **信道宽度**：20MHz/40MHz
- **推荐信道**：1, 6, 11

#### 5GHz频段（802.11a/n/ac/ax）
- **可用信道**：
  - UNII-1：36, 40, 44, 48（室内使用）
  - UNII-2A：52, 56, 60, 64（需要DFS，室内使用）
  - UNII-3：149, 153, 157, 161, 165（室内/室外使用）
- **最大功率**：20dBm（100mW）
- **信道宽度**：20MHz/40MHz/80MHz/160MHz
- **DFS要求**：UNII-2A频段需要动态频率选择

### 功率限制
- **2.4GHz**：≤20dBm（100mW）
- **5GHz**：≤20dBm（100mW）
- **符合标准**：GB 15629.11-2003 / GB 15629.1102-2003

## 配置文件

### /etc/cumbox2/hardware.conf
```bash
# 无线网卡配置 - 中国大陆标准
WIFI_COUNTRY="CN"         # 国家代码：中国
WIFI_REGULATORY_DOMAIN="CN"  # 监管域：中国
WIFI_CHANNEL_2G="1,6,11"  # 2.4GHz信道（中国：1-13）
WIFI_CHANNEL_5G="36,40,44,48,52,56,60,64,149,153,157,161,165"  # 5GHz信道（中国）
WIFI_POWER_LIMIT="20"     # 功率限制(dBm) - 中国标准
WIFI_TX_POWER="20"        # 发射功率(dBm)
WIFI_CHANNELS="13"        # 2.4GHz信道数量（中国：1-13）
```

### /usr/local/cumbox2/scripts/setup_wifi_cn.sh
自动配置脚本，在系统启动时执行，负责：
1. 设置监管域为CN
2. 配置发射功率为20dBm
3. 设置WiFi信道范围
4. 配置NetworkManager/wpa_supplicant

### /lib/systemd/system/cumbox2-wifi-cn.service
Systemd服务，确保每次启动时应用正确的WiFi配置。

## 使用说明

### 查看当前配置
```bash
# 查看监管域
iw reg get

# 查看无线网卡信息
iw dev wlan0 info

# 查看无线网卡状态
iwconfig wlan0

# 查看可用信道
iw list | grep -A 20 "Frequencies:"
```

### 手动应用配置
```bash
# 运行配置脚本
/usr/local/cumbox2/scripts/setup_wifi_cn.sh

# 或者重启服务
systemctl restart cumbox2-wifi-cn.service
```

### 连接WiFi网络
```bash
# 使用nmcli连接（推荐）
nmcli device wifi list
nmcli device wifi connect "SSID" password "密码"

# 使用wpa_supplicant连接
wpa_passphrase "SSID" "密码" >> /etc/wpa_supplicant/wpa_supplicant.conf
systemctl restart wpa_supplicant
```

## 合规说明

### 符合标准
- **SRRC认证**：中国无线电型号核准
- **功率限制**：符合GB 15629.11-2003标准
- **频段使用**：符合中国无线电频率划分规定
- **DFS支持**：5GHz频段支持动态频率选择

### 法规要求
- 2.4GHz频段：免许可使用，功率≤20dBm
- 5GHz频段：免许可使用，功率≤20dBm
- DFS要求：UNII-2A频段必须支持DFS
- 室内外使用：UNII-3频段可用于室外

## 故障排除

### 无法连接WiFi
```bash
# 检查无线网卡是否启用
ip link show wlan0

# 检查监管域是否正确
iw reg get | grep country

# 检查驱动是否加载
lsmod | grep -i wifi

# 查看详细日志
journalctl -u cumbox2-wifi-cn.service -n 50
```

### 信道不可用
```bash
# 检查监管域设置
iw reg get

# 重新设置监管域
iw reg set CN

# 查看支持的信道
iw list | grep -A 20 "Frequencies:" | grep -E "GHz|MHz"
```

### 功率过高
```bash
# 检查当前功率
iwconfig wlan0 | grep "Tx-Power"

# 设置功率为20dBm
iwconfig wlan0 txpower 20

# 或使用iw命令
iw dev wlan0 set txpower fixed 2000  # 2000 = 20.00 dBm
```

## 参考文档

- [中国无线电频率划分规定](http://www.miit.gov.cn/)
- [GB 15629.11-2003 无线局域网标准](http://www.gb688.cn/)
- [SRRC型号核准](http://www.srrc.org.cn/)
- [Linux Wireless Regulatory](https://wireless.wiki.kernel.org/en/developers/Regulatory)

## 注意事项

1. **功率限制**：切勿超过20dBm功率限制，违反无线电管理规定
2. **信道选择**：优先使用推荐信道（1, 6, 11），避免干扰
3. **5GHz使用**：注意DFS要求，避免使用雷达频段
4. **室内外使用**：部分频段仅限室内使用
5. **固件更新**：确保无线网卡固件为最新版本

## 更新日志

- 2026-02-11：创建WiFi中国大陆配置文档
- 配置标准：符合GB 15629.11-2003和中国无线电管理规定
