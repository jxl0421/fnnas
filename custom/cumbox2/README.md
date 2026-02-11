# CumeBox2 硬件适配文件

本目录包含为CumeBox2硬件定制的所有文件，用于在Windows环境下准备固件编译所需的文件，然后通过GitHub Actions进行云端编译。

## 目录结构

```
custom/cumbox2/
├── config/
│   └── hardware.conf         # 硬件配置文件
├── patch/
│   └── cumbox2-dts.patch     # 设备树补丁
├── scripts/
│   ├── oled_system_info.sh   # OLED系统信息显示脚本
│   ├── fan_auto_control.sh   # 风扇自动控制脚本
│   └── key_custom.sh         # 按键自定义脚本
├── systemd/
│   ├── cumbox2-oled.service  # OLED服务
│   ├── cumbox2-fan.service   # 风扇服务
│   └── cumbox2-key.service   # 按键服务
├── install.sh                # 安装脚本
└── README.md                 # 本文件
```

## 功能说明

### 硬件功能
1. **OLED显示屏**：显示IP地址、CPU温度、内存使用率、磁盘使用率和系统时间
2. **风扇自动控制**：根据CPU温度自动调节风扇转速
3. **按键自定义**：自定义电源键和复位键功能
4. **LED指示灯**：适配状态灯和磁盘活动灯
5. **无线网卡支持**：内置WiFi模块自动启用
6. **T95兼容启动**：优化启动地址，解决启动问题

### 系统优化（针对1G内存、8GB存储）
1. **Swap优化**：自动创建2GB swap文件，缓解内存压力
2. **ZRAM内存压缩**：启用512MB压缩内存，提升可用内存
3. **外挂设备自动挂载**：使用标准udisks2自动挂载到/media/（与原项目兼容）
4. **系统性能优化**：优化内核参数、I/O调度、日志管理
5. **服务可靠性**：OLED和风扇服务支持自动重试，确保开机可用
6. **启动地址调整**：T95兼容启动地址优化，解决启动问题

## 启动地址优化

针对T95版本的启动地址进行了以下优化：

- **启动参数调整**：优化启动参数为 `earlyprintk console=ttyS0,115200n8 root=/dev/mmcblk0p1 rootwait ro rootfstype=ext4 console=tty0`
- **启动地址设置**：启动地址调整为 `0x10800000`（T95标准启动地址）
- **内存配置**：1GB内存配置优化
- **设备树兼容**：与T95启动地址保持一致，确保启动兼容性
- **设备树补丁**：完整的硬件节点配置（OLED、风扇、LED、按键等）
- **启动可靠性**：固件直接包含完整配置，无需启动修复脚本

## 注意事项

1. **启动兼容性**：T95启动地址优化（0x10800000）确保与T95固件的启动兼容性
2. **设备树补丁**：启动地址调整通过设备树补丁实现，包含完整硬件配置
3. **固件编译**：编译时自动应用T95启动地址补丁
4. **启动测试**：建议在刷写固件后测试启动功能
5. **无启动修复脚本**：固件已包含完整配置，无需运行启动修复脚本

如遇到启动问题，请检查：
- 设备树补丁是否正确应用
- 启动参数是否匹配
- 内存配置是否正确
- 启动地址设置是否生效（0x10800000）
- 硬件服务状态：`systemctl status cumbox2-oled cumbox2-fan cumbox2-key`

## 使用方法

### 优化配置说明

**硬件配置**：1G内存 + 8GB存储

**分区方案**：
- 根分区：8GB（可扩展，默认8GB）
- 系统预留：留出空间给数据和缓存

**内存优化**：
- Swap：2GB（内存的2倍）
- ZRAM：512MB压缩内存
- 内存压缩算法：lzo-rle（性能优先）

**存储优化**：
- 外挂设备自动挂载到：/mnt/storage
  - USB设备 → /mnt/storage/usb
  - SATA设备 → /mnt/storage/sata
  - NVMe设备 → /mnt/storage/nvme
- 自动检测SSD并优化I/O

**自定义配置**：
编辑 `config/optimization.conf` 可以调整：
- Swap大小
- ZRAM大小
- 内存压缩算法
- 系统参数

### 方法一：使用优化的CumeBox2工作流（推荐）

1. **准备环境**：
   - 在Windows下安装Git: https://git-scm.com/download/win
   - 安装VSCode: https://code.visualstudio.com/Download
   - 在VSCode中设置文件换行符为LF（CRLF → LF）

2. **配置GitHub仓库**：
   - 在GitHub上Fork ophub/fnnas仓库到你的账号
   - 克隆到本地：`git clone https://github.com/你的用户名/fnnas.git`
   - 进入仓库目录：`cd fnnas`

3. **添加CumeBox2适配文件**：
   - 确保本目录（custom/cumbox2/）及其子目录中的所有文件都已正确放置
   - 根据实际硬件修改 `config/hardware.conf` 文件中的GPIO配置

4. **推送到GitHub**：
   ```bash
   git add .
   git commit -m "添加CumeBox2硬件适配文件"
   git push origin main
   ```

5. **触发编译**：
   - 访问你的GitHub仓库页面
   - 点击 "Actions" 标签
   - 选择 "Build CumeBox2 FnNAS Image" 工作流
   - 点击 "Run workflow" 按钮
   - 选择所需的内核版本（6.12.y 或 6.18.y）
   - 点击 "Run workflow" 开始编译

6. **下载固件**：
   - 编译完成后，在Actions页面查看编译结果
   - 固件会自动发布到Releases页面，标签为 `cumbox2_fnnas`
   - 下载编译好的固件文件

### 方法二：使用批处理脚本

1. 在项目根目录下运行 `cumbox2_push.bat`
2. 按照提示输入GitHub用户名和邮箱
3. 脚本会自动完成Git配置和推送操作
4. 然后按照方法一的步骤5-6触发编译和下载固件

## 工作流特点

- **高速编译**：只编译CumeBox2（S905X）设备的固件，不编译其他设备
- **灵活配置**：支持选择不同内核版本和根分区大小
- **自动发布**：编译完成后自动发布到GitHub Releases
- **云端编译**：使用GitHub Actions的Ubuntu 24.04环境，无需本地Linux

## 编译参数说明

- **fnnas_kernel**: 内核版本选择
  - `6.12.y`: 6.12系列最新版本
  - `6.18.y`: 6.18系列最新版本
  - `6.12.y_6.18.y`: 同时编译两个内核版本

- **auto_kernel**: 是否自动使用同系列最新内核
  - `true`: 自动升级到最新版本
  - `false`: 使用指定版本

- **rootfs_expand**: 根分区扩容大小（GiB）
  - **默认：8 GiB**（针对8GB存储优化）
  - 建议值：6-8GB（留出空间给数据和缓存）
  - 如果使用外挂存储，可以设置更小（如4-6GB）

- **builder_name**: 构建者签名
  - 默认：cumbox2

### 推荐配置（针对1G内存、8GB存储）
```
fnnas_kernel: 6.12.y
auto_kernel: true
rootfs_expand: 8
builder_name: cumbox2
```

## 注意事项

1. **文件编码**：所有脚本文件使用UTF-8编码
2. **换行符**：所有脚本文件使用LF换行符（Unix格式），在Windows下编辑时请确保VSCode设置正确
3. **硬件配置**：根据实际硬件参数修改 `hardware.conf` 文件
4. **GPIO引脚**：如需修改GPIO引脚，请同时修改硬件配置文件和设备树补丁文件
5. **编译时间**：只编译CumeBox2设备的固件，通常需要15-30分钟

## 固件刷写

1. 下载编译好的固件文件
2. 使用BalenaEtcher等工具刷写到TF卡/U盘
3. 将刷好的TF卡/U盘插入CumeBox2
4. 开机，系统会自动启动并加载CumeBox2的硬件配置

## 故障排除

- **编译失败**：检查Actions日志，查看具体错误信息
- **补丁应用失败**：检查设备树补丁文件格式是否正确
- **硬件不工作**：检查hardware.conf中的GPIO配置是否正确
- **服务启动失败**：检查服务状态：`systemctl status cumbox2-oled cumbox2-fan cumbox2-key`
- **查看服务日志**：`journalctl -u cumbox2-* -f`

## 支持

如有问题，请查看：
- [FnNAS官方文档](https://github.com/ophub/fnnas)
- [amlogic-s9xxx-armbian项目](https://github.com/ophub/amlogic-s9xxx-armbian)
- 查看内核日志：`dmesg | grep -i "i2c\|gpio\|oled\|fan"`
- 查看服务日志：`journalctl -u cumbox2-* -n 100`