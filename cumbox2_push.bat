@echo off
chcp 65001 >nul
echo CumeBox2硬件适配文件推送脚本
echo ==============================
echo.

:: 检查Git是否安装
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到Git，请先安装Git: https://git-scm.com/download/win
    pause
    exit /b 1
)

:: 检查是否在Git仓库中
if not exist .git (
    echo [错误] 当前目录不是Git仓库
    echo 请先克隆FnNAS仓库到本地：
    echo git clone https://github.com/你的用户名/fnnas.git
    pause
    exit /b 1
)

:: 检查custom/cumbox2目录是否存在
if not exist custom\cumbox2 (
    echo [错误] 未找到custom\cumbox2目录
    echo 请确保CumeBox2适配文件已正确放置
    pause
    exit /b 1
)

echo [信息] Git版本：
git --version
echo.

:: 获取用户输入
set /p username=请输入GitHub用户名: 
set /p email=请输入GitHub邮箱: 

echo.
echo [信息] 正在配置Git...
git config --global user.name "%username%"
git config --global user.email "%email%"
echo [成功] Git配置完成
echo.

:: 检查是否有修改
git diff --quiet && git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [提示] 没有检测到文件修改
    echo 如果这是首次推送，请按任意键继续...
    pause >nul
)

:: 添加文件
echo [信息] 正在添加所有文件...
git add .
if %errorlevel% neq 0 (
    echo [错误] Git add 失败
    pause
    exit /b 1
)
echo [成功] 文件添加完成
echo.

:: 提交更改
echo [信息] 正在提交更改...
git commit -m "添加CumeBox2硬件适配文件，无挖矿内容"
if %errorlevel% neq 0 (
    echo [提示] 没有新的提交（可能文件未修改）
    echo 继续推送...
) else (
    echo [成功] 提交完成
)
echo.

:: 检查远程仓库
git remote -v | findstr origin >nul
if %errorlevel% neq 0 (
    echo [错误] 未配置远程仓库
    echo 请添加远程仓库：
    echo git remote add origin https://github.com/%username%/fnnas.git
    pause
    exit /b 1
)

:: 推送到远程仓库
echo [信息] 正在推送到GitHub...
echo 这可能需要几分钟时间，请耐心等待...
echo.
git push origin main
if %errorlevel% neq 0 (
    echo.
    echo [错误] 推送失败
    echo 可能的原因：
    echo 1. 网络连接问题
    echo 2. GitHub认证失败（可能需要设置Personal Access Token）
    echo 3. 分支名称不正确
    echo.
    echo 请检查后重试
    pause
    exit /b 1
)

echo.
echo ==============================
echo [成功] 推送完成！
echo.
echo 下一步操作：
echo 1. 访问GitHub仓库页面：https://github.com/%username%/fnnas
echo 2. 点击 "Actions" 标签
echo 3. 选择 "Build CumeBox2 FnNAS Image" 工作流
echo 4. 点击 "Run workflow" 按钮
echo 5. 选择内核版本（推荐使用 6.12.y）
echo 6. 点击 "Run workflow" 开始编译
echo.
echo 编译完成后，固件将自动发布到Releases页面
echo ==============================
echo.
pause