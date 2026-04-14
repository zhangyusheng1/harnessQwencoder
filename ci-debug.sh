#!/bin/bash

echo "=== 开始CI构建失败诊断 ==="

# 1. 检查是否有语法错误（HTML/CSS项目示例）
echo "检查代码语法..."
if [ -d "src" ] || [ -f "*.html" ] || [ -f "*.css" ]; then
    # 对于HTML/CSS项目，使用标准工具检查语法
    if command -v htmlhint &> /dev/null; then
        htmlhint "**/*.html" || echo "❌ HTML语法检查失败"
    else
        echo "ℹ️ htmlhint未安装，跳过HTML语法检查"
    fi
    
    if command -v stylelint &> /dev/null; then
        stylelint "**/*.css" || echo "❌ CSS语法检查失败"
    else
        echo "ℹ️ stylelint未安装，跳过CSS语法检查"
    fi
else
    echo "ℹ️ 未检测到HTML/CSS源码文件"
fi

# 2. 检查代码风格/格式
echo "检查代码格式..."
if command -v prettier &> /dev/null; then
    prettier --check "**/*.{html,css}" || echo "❌ 代码格式检查失败"
else
    echo "ℹ️ Prettier未安装，跳过格式检查"
fi

# 3. 运行单元测试
echo "运行测试..."
if [ -f "package.json" ]; then
    npm test || echo "❌ 单元测试失败"
else
    echo "ℹ️ 未找到package.json，跳过npm测试"
fi

# 4. 验证依赖项
echo "验证依赖..."
if [ -f "package.json" ]; then
    npm install --only=prod --dry-run || echo "❌ 依赖解析失败"
else
    echo "ℹ️ 未找到package.json，跳过依赖验证"
fi

# 5. 查找CI日志
echo "查找CI日志..."
find . -name "*.log" -o -name "*.ci*" -o -name "*.build*" | head -10

# 6. 显示当前变更
echo "当前Git状态:"
git status

echo "=== 诊断完成 ==="