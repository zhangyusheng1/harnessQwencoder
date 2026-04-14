# 通义灵码 (Lingma) CLI 工具安装指南

## 概述
通义灵码是阿里巴巴云提供的智能编程助手，支持命令行接口 (CLI) 用于自动化开发任务。Harness Agent 依赖此工具执行任务拆分和代码生成。

## 安装方法

### 方法 1: 通过官方渠道安装（推荐）

1. **访问通义灵码官网**
   - 前往 [通义灵码官方网站](https://tongyi.aliyun.com/lingma/)
   - 登录您的阿里云账号

2. **下载 CLI 工具**
   - 在控制台中找到 "开发者工具" 或 "CLI 下载" 选项
   - 根据您的操作系统下载对应的 CLI 工具：
     - Windows: `lingma-cli-windows-amd64.exe`
     - macOS: `lingma-cli-darwin-amd64`
     - Linux: `lingma-cli-linux-amd64`

3. **安装配置**
   ```bash
   # Windows (PowerShell)
   # 将下载的 exe 文件重命名为 lingma.exe
   # 将其放置在 PATH 环境变量包含的目录中，如 C:\Windows\System32\
   
   # macOS/Linux
   chmod +x lingma-cli-*
   sudo mv lingma-cli-* /usr/local/bin/lingma
   ```

4. **配置认证**
   ```bash
   # 初始化配置
   lingma config init
   
   # 设置 API 密钥（从阿里云控制台获取）
   lingma config set api-key YOUR_API_KEY
   
   # 设置工作区
   lingma config set workspace .
   ```

### 方法 2: 通过包管理器安装（如果可用）

```bash
# 如果 lingma CLI 发布到 npm
npm install -g @alibaba/lingma-cli

# 如果发布到 pip
pip install tongyi-lingma-cli

# 如果发布到 Homebrew (macOS)
brew tap alibaba/tongyi
brew install lingma-cli
```

### 方法 3: 从源码构建（高级用户）

```bash
# 克隆官方仓库（如果公开）
git clone https://github.com/alibaba/lingma-cli.git
cd lingma-cli
make build
sudo make install
```

## 验证安装

安装完成后，验证 lingma CLI 是否正常工作：

```bash
# 检查版本
lingma --version

# 测试基本功能
lingma quest --help
lingma agent --help

# 测试与 Harness 集成
bash harness/scripts/harness-loop.sh "测试任务" TEST-001
```

## 故障排除

### 常见问题

1. **命令未找到错误**
   - 确保 lingma 可执行文件在系统 PATH 中
   - Windows 用户可能需要重启终端或重新加载环境变量

2. **认证失败**
   - 检查 API 密钥是否正确
   - 确保阿里云账号有足够的权限
   - 验证网络连接是否正常

3. **权限问题**
   - Linux/macOS: 确保文件有执行权限 (`chmod +x`)
   - Windows: 确保 PowerShell 执行策略允许脚本运行

### 调试步骤

```bash
# 启用详细日志
lingma --debug quest run --prompt "test"

# 检查配置
lingma config list

# 查看帮助文档
lingma --help
```

## 与 Harness 集成

安装完成后，Harness 脚本将能够正常调用 lingma 命令：

- `harness/scripts/harness-loop.sh` - 主工作流脚本
- `harness/scripts/mcp-prototype-tool.sh` - 原型图处理工具

确保您的 `.env` 文件包含正确的配置：

```bash
# .env
LINGMA_API_KEY=your-api-key-here
LINGMA_WORKSPACE_ID=your-workspace-id
```

## 注意事项

- **API 使用限制**: 注意阿里云 API 的调用频率和配额限制
- **安全**: 不要将 API 密钥提交到版本控制系统
- **兼容性**: 确保使用的 lingma CLI 版本与 Harness 配置兼容

## 支持资源

- [通义灵码官方文档](https://help.aliyun.com/product/lingma.html)
- [阿里云技术支持](https://workorder.console.aliyun.com/)
- [GitHub Issues](https://github.com/alibaba/lingma-cli/issues) (如果开源)