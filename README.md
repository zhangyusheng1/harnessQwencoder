# Harness Project - OpenAI Standard Implementation

## 项目概述
这是一个基于 OpenAI Harness 标准的自动化开发框架，实现了完整的 AI 驱动开发闭环：
- 任务拆分 → 分支创建 → 代码编写 → 测试 → 提交 → PR → 校验 → 修复 → 合并

## 核心组件

### 1. Harness Agent
- 遵循 `harness/prompts/agent-harness-prompt.txt` 严格规范
- 自主执行全开发闭环流程
- 支持 MCP (Model Context Protocol) 集成

### 2. MCP 原型图集成
- 支持 Pixso 平台 (`https://pixso.cn/`)
- 实现 1:1 像素级 UI 还原
- 自动提取设计规范并生成代码

### 3. 自动化工作流
- `harness/scripts/harness-loop.sh` - 主工作流脚本
- `harness/scripts/mcp-prototype-tool.sh` - 原型图处理工具

## 依赖工具

### 必需工具
- **通义灵码 (Lingma) CLI** - 核心 AI 编程助手
- **Git** - 版本控制
- **GitHub CLI (gh)** - PR 管理
- **YQ** - YAML 处理
- **Maven** - Java 项目构建 (如果适用)

### 安装 Lingma CLI

详细安装指南请参考：[docs/agents/LINGMA_INSTALLATION.md](docs/agents/LINGMA_INSTALLATION.md)

#### 快速开始
1. 访问 [通义灵码官网](https://tongyi.aliyun.com/lingma/)
2. 下载对应操作系统的 CLI 工具
3. 配置 API 密钥和工作区
4. 验证安装：`lingma --version`

## 项目结构

```
.
├── config/                  # 配置文件
│   └── secrets/             # 敏感配置（gitignored）
├── docs/                    # 文档
│   ├── agents/              # Agent 相关文档
│   ├── architecture/        # 架构规范
│   └── coding-standards/    # 编码标准
├── harness/                 # Harness 核心配置
│   ├── prompts/             # Agent 提示词
│   ├── scripts/             # 自动化脚本
│   ├── config.yaml          # Harness 配置
│   └── mcp-config.yaml      # MCP 配置
├── prototype/               # 设计原型图
├── src/                     # 源代码
├── tests/                   # 测试代码
├── .env                     # 环境变量
└── .gitignore               # Git 忽略规则
```

## 使用示例

### 执行原型图还原任务
```bash
# 使用 Git Bash 或 WSL（Windows 推荐）
bash harness/scripts/harness-loop.sh "根据以下本地原型图1:1还原页面，像素级还原布局、颜色、间距、字体、按钮、表单、交互，严格按照设计图实现：
1. 路径：prototype/ContentArea.png
2. 路径：prototype/StatusBar.png  
3. 路径：prototype/TabBar.png
" WEB-001
```

### 直接处理原型图
```bash
# 使用 MCP 原型工具
bash harness/scripts/mcp-prototype-tool.sh "prototype/ContentArea.png prototype/StatusBar.png prototype/TabBar.png" WEB-001
```

## 配置说明

### 环境变量 (.env)
```bash
# Pixso MCP 配置
PIXSO_SESSION_COOKIE=your-browser-session-cookie

# Lingma 配置  
LINGMA_API_KEY=your-lingma-api-key

# 路径配置
PROTOTYPE_BASE_PATH=prototype/
```

### 安全注意事项
- `config/secrets/` 目录已加入 `.gitignore`
- 不要提交敏感信息到版本控制系统
- 使用浏览器会话 Cookie 时注意安全

## 故障排除

如果遇到脚本执行失败，请检查：
1. 所有依赖工具是否已正确安装
2. 环境变量是否正确配置
3. 网络连接是否正常
4. API 配额是否充足

详细故障排除指南请参考各组件的文档。

## 许可证
此项目遵循 OpenAI Harness 标准，具体许可证信息请参考相关文档。