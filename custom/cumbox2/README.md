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

1. **OLED显示屏**：显示IP地址、CPU温度、内存使用率、磁盘使用率和系统时间
2. **风扇自动控制**：根据CPU温度自动调节风扇转速
3. **按键自定义**：自定义电源键和复位键功能
4. **LED指示灯**：适配状态灯和磁盘活动灯
5. **无线网卡支持**：内置WiFi模块自动启用

## 使用方法

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
  - 默认：16 GiB
  - 可根据需要调整

- **builder_name**: 构建者签名
  - 默认：cumbox2

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

## 支持

如有问题，请查看：
- [FnNAS官方文档](https://github.com/ophub/fnnas)
- [amlogic-s9xxx-armbian项目](https://github.com/ophub/amlogic-s9xxx-armbian)