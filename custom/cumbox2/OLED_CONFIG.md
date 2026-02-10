# CumeBox2 OLED显示屏配置说明

## 硬件信息

根据图片显示，CumeBox2使用的是：
- **OLED型号**: 0.96英寸SSD1306 I2C OLED显示屏
- **I2C地址**: 0x3c (也可配置为0x7a)
- **分辨率**: 80x40像素
- **接口**: I2C总线

## 配置文件

### hardware.conf 配置

```bash
# OLED配置
OLED_I2C_BUS="0"           # I2C总线号 (通常为0)
OLED_I2C_ADDR="0x3c"       # I2C地址 (0x3c或0x7a)
OLED_WIDTH="80"           # OLED宽度 (像素)
OLED_HEIGHT="40"          # OLED高度 (像素)
OLED_DRIVER="ssd1306"      # OLED驱动型号
OLED_ROTATE="0"           # 显示旋转角度 (0=正常, 1=180度旋转)
```

## 驱动支持

### 内核驱动
系统使用`ssd1306fb`驱动，支持以下功能：
- I2C通信
- framebuffer显示
- 自动检测和加载

### 驱动检测机制
脚本包含完善的驱动检测和自动重试机制：
1. 检查`ssd1306`模块是否已加载
2. 尝试加载驱动
3. 通过i2cdetect检测设备
4. 支持多次重试

## 显示内容

OLED显示以下系统信息：
- **IP地址**: 网络接口IP
- **CPU温度**: 系统CPU温度
- **内存使用率**: 系统内存使用百分比
- **磁盘使用率**: 根分区使用率
- **系统时间**: 当前时间
- **系统负载**: CPU负载平均值

## 调试和故障排除

### 常见问题

1. **OLED不显示**
   - 检查I2C总线是否正确 (`/dev/i2c-0`)
   - 检查设备地址是否正确 (`0x3c`)
   - 检查驱动是否加载 (`lsmod | grep ssd1306`)

2. **显示内容异常**
   - 检查显示旋转设置 (`OLED_ROTATE`)
   - 检查分辨率设置 (`OLED_WIDTH`, `OLED_HEIGHT`)

3. **驱动加载失败**
   - 确保内核版本支持
   - 检查I2C设备 (`i2cdetect -y 0`)

### 调试命令

```bash
# 检查I2C设备
i2cdetect -y 0

# 检查驱动加载
lsmod | grep ssd1306

# 检查framebuffer
ls -l /dev/fb*

# 查看服务状态
systemctl status cumbox2-oled
journalctl -u cumbox2-oled -f
```

## 与官方文档的对比

参考[ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/documents/led_screen_display_control.md)文档，我们的配置：

- 使用标准的I2C OLED驱动，而非VFD显示
- 支持自动检测和配置
- 包含完善的错误处理和重试机制
- 适配CumeBox2的硬件规格

## 注意事项

1. 确保I2C总线已启用 (通常需要在设备树中配置)
2. OLED显示屏需要稳定的电源供应
3. 避免在高温环境下长时间使用
4. 定期检查连接是否松动

## 升级建议

如需升级OLED固件或驱动，请：
1. 备份当前配置
2. 更新内核版本
3. 测试新版本驱动兼容性
4. 调整配置参数

## 技术支持

如遇到问题，请提供以下信息：
1. OLED型号和规格
2. 当前配置文件内容
3. 系统日志 (`journalctl -u cumbox2-oled`)
4. 驱动加载状态 (`lsmod | grep ssd1306`)