@echo off
REM 真实的 Lingma CLI 工具 - Windows 批处理包装器
REM 设置环境变量并调用 Python 实现

setlocal

REM 读取 .env 文件中的 LINGMA_API_KEY
for /f "tokens=1,2 delims==" %%a in ('findstr /b /c:"LINGMA_API_KEY=" .env') do (
    set "LINGMA_API_KEY=%%b"
)

REM 调用 Python 脚本
python "%~dp0lingma-real.py" %*

endlocal