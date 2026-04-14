harness-project/
├── .github/workflows/          # CI/CD 自动校验闭环（对标OpenAI CI）
│   └── harness-pr-validate.yml  # PR自动校验+自动修复流水线
├── docs/                       # 结构化上下文知识库（仓库即真理）
│   ├── architecture/           # 架构规范、分层约束、依赖规则
│   ├── coding-standards/       # 编码规范、命名、格式、测试要求
│   ├── specs/                  # 需求Spec、任务拆分、验收标准
│   └── agents/                 # Agent专用文档、工具说明、修复指南
├── harness/                    # Harness核心管控层（OpenAI核心）
│   ├── AGENTS.md               # 精简导航（≤100行，指向所有规则）
│   ├── config.yaml             # 全局Harness约束、PR/分支/校验规则
│   ├── lint-rules/             # 自定义架构Lint（护栏）
│   ├── scripts/                # 闭环编排、自动修复、PR脚本
│   └── prompts/                 # 通义灵码Agent/Quest专用Prompt模板
├── src/                        # 业务代码（Agent受控修改）
├── tests/                      # 单元/集成测试（自动生成+执行）
├── .gitignore
├── PR_TEMPLATE.md              # AI自动生成PR的标准模板
└── README.md                    # 工程说明、快速开始