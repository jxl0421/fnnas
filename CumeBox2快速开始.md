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
3. 选择编译参数：
   - **fnnas_kernel**: 选择 `6.12.y`（推荐）
   - **auto_kernel**: 保持 `true`
   - **rootfs_expand**: 保持 `16`
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

### 8.1 OLED显示
- OLED屏幕应显示：
  - IP地址
  - CPU温度
  - 内存使用率
  - 磁盘使用率
  - 系统时间

### 8.2 风扇控制
- CPU温度低于50℃时，风扇停止
- CPU温度高于50℃时，风扇启动

### 8.3 按键功能
- 长按电源键：关机
- 长按复位键：重启

### 8.4 LED指示灯
- 状态灯：心跳闪烁
- 磁盘灯：磁盘活动时闪烁

## 九、常见问题

### Q1: 编译失败怎么办？
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