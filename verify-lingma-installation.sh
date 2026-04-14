#!/bin/bash
# 验证 Lingma 安装的脚本

echo "=== 验证 Lingma 安装 ==="

# 1. 检查 lingma 命令是否可用
if command -v lingma &> /dev/null; then
    echo "✅ lingma 命令可用"
else
    echo "❌ lingma 命令不可用"
    echo "请确保 lingma 脚本在 PATH 中，或者在当前目录运行"
fi

# 2. 检查 .env 文件是否存在
if [ -f ".env" ]; then
    echo "✅ .env 文件存在"
    
    # 检查 API 密钥是否配置
    if grep -q "your-actual-api-key-here" .env; then
        echo "⚠️  .env 文件中的 LINGMA_API_KEY 需要替换为实际的 API 密钥"
    else
        echo "✅ .env 文件中的 LINGMA_API_KEY 已配置"
    fi
else
    echo "❌ .env 文件不存在"
fi

# 3. 检查 secrets 文件是否存在
if [ -f "config/secrets/mcp-secrets.yaml" ]; then
    echo "✅ secrets 文件存在"
    
    # 检查 API 密钥是否配置
    if grep -q "your-actual-lingma-api-key-here" config/secrets/mcp-secrets.yaml; then
        echo "⚠️  secrets 文件中的 api_key 需要替换为实际的 API 密钥"
    else
        echo "✅ secrets 文件中的 api_key 已配置"
    fi
else
    echo "❌ secrets 文件不存在"
fi

# 4. 测试基本功能（不调用 API）
echo ""
echo "=== 测试基本功能 ==="
echo "运行: lingma quest --prompt 'test' --output harness/tasks/test.txt"
mkdir -p harness/tasks
if ./lingma quest --prompt "test" --output harness/tasks/test.txt 2>&1 | head -5; then
    echo "✅ 基本功能测试通过"
else
    echo "⚠️  基本功能测试显示需要配置 API 密钥"
fi

echo ""
echo "=== 安装验证完成 ==="
echo ""
echo "下一步操作:"
echo "1. 访问 https://tongyi.aliyun.com/lingma/ 获取 API 密钥"
echo "2. 更新 .env 文件中的 LINGMA_API_KEY"
echo "3. 更新 config/secrets/mcp-secrets.yaml 中的 api_key"
echo "4. 重新运行验证脚本"