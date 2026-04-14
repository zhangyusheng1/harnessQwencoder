# AGENTS.md (Harness Navigation Map - OpenAI Standard)
# 仅保留核心导航，不塞冗余内容，防止上下文溢出
## 1. 架构约束（必须遵守）
- 架构规范：docs/architecture/architecture-rules.md
- 分层依赖：docs/architecture/layer-dependencies.md
- 禁止行为：docs/architecture/forbidden-practices.md

## 2. 编码规范
- Java规范：docs/coding-standards/java.md
- 测试规范：docs/coding-standards/testing.md
- PR规范：docs/coding-standards/pr-guidelines.md

## 3. Harness 执行规则
- 全局约束：harness/config.yaml
- 校验命令：harness/config.yaml#validation.commands
- 修复流程：harness/scripts/auto-repair.sh

## 4. 工具权限
- 允许修改：src/**, tests/**
- 禁止修改：config/secrets/**, docs/architecture/** (只读)
- 允许命令：git, mvn, pytest, gh (PR工具)