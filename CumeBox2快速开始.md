# CumeBox2 快速开始指南

## 一、准备工作（一次性）

### 1.1 安装必要工具
- **Git**: https://git-scm.com/download/win
- **VSCode**: https://code.visualstudio.com/Download

### 1.2 VSCode设置
1. 打开VSCode
2. 按 `Ctrl + ,` 打开设置
3. 搜索 `files.eol`，设置为 `\n`
4. 搜索 `files.encoding`，设置为 `utf8`

## 系统配置说明

### 硬件配置
- **内存**：1GB
- **存储**：8GB（可外挂存储设备）

### 优化方案

**分区配置**：
- 根分区：8GB（默认，可扩展）
- 剩余空间：用于数据和缓存

**内存优化**：
- **Swap**：2GB（内存的2倍）
- **ZRAM**：512MB压缩内存
- **内存压缩算法**：lzo-rle（性能优先）

**存储优化**：
- **外挂设备自动挂载**：
  - USB设备 → /mnt/storage/usb
  - SATA设备 → /mnt/storage/sata
  - NVMe设备 → /mnt/storage/nvme
- **SSD缓存**：自动检测SSD并优化I/O

**系统优化**：
- 内核参数优化（swappiness、脏页等）
- I/O调度器优化
- 日志轮转优化
- 禁用不必要的服务

## 二、获取项目

### 2.1 Fork仓库
1. 访问 https://github.com/ophub/fnnas
2. 点击右上角 "Fork" 按钮
3. 选择你的GitHub账号

### 2.2 克隆到本地
```bash
git clone https://github.com/你的用户名/fnnas.git
cd fnnas
```

## 三、配置CumeBox2适配

### 3.1 硬件配置文件
编辑 `custom/cumbox2/config/hardware.conf`，根据实际硬件修改：

```bash
# OLED配置
OLED_I2C_BUS="0"          # I2C总线号
OLED_I2C_ADDR="0x3c"      # I2C地址
OLED_WIDTH="80"           # OLED宽度
OLED_HEIGHT="40"          # OLED高度

# 风扇配置
FAN_GPIO="AO_3"           # 风扇GPIO
FAN_TEMP_LOW="50"         # 低温阈值（℃）
FAN_TEMP_HIGH="70"        # 高温阈值（℃）

# LED配置
LED_STATUS_GPIO="X_49"     # 状态灯GPIO
LED_DISK_GPIO="X_4B"       # 磁盘灯GPIO

# 按键配置
KEY_POWER_GPIO="AO_2"      # 电源键GPIO
KEY_RESET_GPIO="AO_9"      # 复位键GPIO
```

### 3.2 检查文件结构
确保以下目录和文件都存在：
```
custom/cumbox2/
├── config/hardware.conf
├── patch/cumbox2-dts.patch
├── scripts/
│   ├── oled_system_info.sh
│   ├── fan_auto_control.sh
│   └── key_custom.sh
├── systemd/
│   ├── cumbox2-oled.service
│   ├── cumbox2-fan.service
│   └── cumbox2-key.service
└── install.sh
```

## 四、推送到GitHub

### 方法一：使用批处理脚本（推荐）
```bash
# 双击运行项目根目录下的 cumbox2_push.bat
# 按照提示输入GitHub用户名和邮箱
```

### 方法二：手动推送
```bash
git add .
git commit -m "添加CumeBox2硬件适配文件"
git push origin main
```

## 五、编译固件

### 5.1 打开GitHub Actions
1. 访问你的GitHub仓库：`https://github.com/你的用户名/fnnas`
2. 点击顶部的 "Actions" 标签

### 5.2 运行工作流
1. 左侧选择 "Build CumeBox2 FnNAS Image"
2. 点击右侧 "Run workflow" 按钮
3. 选择编译参数（针对1G内存、8GB存储优化）：
   - **fnnas_kernel**: 选择 `6.12.y`（推荐）
   - **auto_kernel**: 保持 `true`
   - **rootfs_expand**: 设置为 `8`（推荐，适合8GB存储）
   - **builder_name**: 保持 `cumbox2`
4. 点击 "Run workflow" 开始编译

### 5.3 查看编译进度
- 点击正在运行的任务查看实时日志
- 编译时间通常为 15-30 分钟
- 编译成功后会自动上传到Releases

## 六、下载固件

### 6.1 从Releases下载
1. 访问你的GitHub仓库
2. 点击 "Releases" 标签
3. 找到标签为 `cumbox2_fnnas` 的版本
4. 下载 `.img` 或 `.img.xz` 文件

### 6.2 从Actions下载（如果Releases未自动发布）
1. 在Actions页面，点击完成的编译任务
2. 滚动到页面底部的 "Artifacts" 区域
3. 点击下载固件文件

## 七、刷写固件

### 7.1 使用BalenaEtcher
1. 下载 BalenaEtcher: https://www.balena.io/etcher/
2. 选择下载的固件文件
3. 插入8GB以上的TF卡或U盘
4. 点击 "Flash!" 开始刷写

### 7.2 启动设备
1. 将刷好固件的TF卡/U盘插入CumeBox2
2. 连接HDMI显示器、键盘和网线
3. 上电启动
4. 系统会自动启动并加载CumeBox2配置

## 八、验证功能

### 8.1 服务状态检查
安装完成后，可以使用服务检查脚本查看所有硬件服务的状态：

```bash
/usr/local/cumbox2/scripts/check_services.sh
```

该脚本会检查：
1. OLED显示服务状态和日志
2. 风扇控制服务状态和日志
3. 按键服务状态和日志
4. ZRAM内存压缩状态
5. 内存和Swap状态
6. 外挂设备挂载状态
7. I2C设备检测
8. GPIO导出状态

### 8.2 系统优化验证

**检查内存状态**：
```bash
free -h
```
应该看到：
- Total: 约1GB（物理内存）
- Swap: 约2GB
- ZRAM: 约512MB

**检查挂载状态**：
```bash
df -h /mnt/storage
ls -la /mnt/storage/
```
应该看到自动创建的挂载点：
- /mnt/storage/usb
- /mnt/storage/sata
- /mnt/storage/nvme

**检查系统优化**：
```bash
cat /proc/sys/vm/swappiness
# 应该输出：10

cat /sys/kernel/mm/transparent_hugepage/enabled
# 应该输出：[never]
```

### 8.2 OLED显示
- OLED屏幕应显示：
  - IP地址
  - CPU温度
  - 内存使用率
  - 磁盘使用率
  - 系统时间

### 8.2 服务状态检查
开机后，硬件服务会自动启动并持续运行。如果首次启动失败，服务会自动重试。

**查看服务状态**：
```bash
systemctl status cumbox2-oled
systemctl status cumbox2-fan
systemctl status cumbox2-key
```

**查看服务日志**：
```bash
journalctl -u cumbox2-oled -f
journalctl -u cumbox2-fan -f
journalctl -u cumbox2-key -f
```

**服务重启机制**：
- OLED服务：启动失败后10秒自动重试
- 风扇服务：启动失败后10秒自动重试
- 按键服务：启动失败后10秒自动重试
- 所有服务都设置为始终重启（Restart=always）

### 8.3 风扇控制
- CPU温度低于50℃时，风扇停止
- CPU温度高于50℃时，风扇启动

### 8.3 按键功能
- 长按电源键：关机
- 长按复位键：重启

### 8.4 LED指示灯
- 状态灯：心跳闪烁
- 磁盘灯：磁盘活动时闪烁

## 九、常见问题

### Q1: 开机后OLED不显示？
A:
1. 检查服务状态：`systemctl status cumbox2-oled`
2. 查看服务日志：`journalctl -u cumbox2-oled -n 50`
3. 确认I2C总线配置是否正确：`i2cdetect -y 0`
4. 服务会自动重试，等待1-2分钟看是否恢复

### Q2: 风扇不转动？
A:
1. 检查GPIO配置是否正确
2. 查看服务日志：`journalctl -u cumbox2-fan -n 50`
3. 检查CPU温度是否超过50℃：`cat /sys/class/thermal/thermal_zone0/temp`
4. 服务会自动重试，等待1-2分钟看是否恢复

### Q3: 服务启动失败？
A:
- 系统会自动重试服务（每10秒一次）
- 查看服务日志了解具体错误：`journalctl -u cumbox2-* -n 100`
- 如果持续失败，检查硬件配置文件是否正确

### Q4: 外挂设备不自动挂载？
A:
1. 系统使用标准udisks2挂载（兼容原项目）
2. 手动挂载：`udiskie --tray --automount --notify`（需要图形界面）
3. 或使用命令行：`udisksctl mount -b /dev/sdX1`
4. 挂载位置：/media/（根据设备标签或UUID自动创建）

### Q5: 编译失败怎么办？
A: 查看Actions日志，定位错误信息，常见原因：
- 网络连接问题
- 文件格式错误（确保使用LF换行符）
- GitHub Token权限不足

### Q2: OLED不显示？
A: 检查hardware.conf中的I2C配置是否正确

### Q3: 风扇不转动？
A: 检查GPIO配置是否正确，确保温度传感器工作正常

### Q4: 如何重新编译？
A: 修改配置文件后，重新推送到GitHub，再次触发Actions编译

## 十、进阶配置

### 10.1 自定义OLED显示内容
编辑 `custom/cumbox2/scripts/oled_system_info.sh`

### 10.2 调整风扇温度阈值
编辑 `custom/cumbox2/config/hardware.conf` 中的：
- `FAN_TEMP_LOW`: 低温阈值
- `FAN_TEMP_HIGH`: 高温阈值

### 10.3 自定义按键功能
编辑 `custom/cumbox2/scripts/key_custom.sh`

## 技术支持

- **项目地址**: https://github.com/ophub/fnnas
- **文档**: 查看项目README了解更多信息
- **Issues**: 遇到问题可以提交Issue

## 许可证

本项目遵循 GPL-2.0 许可证