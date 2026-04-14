#!/bin/bash
# OpenAI Harness 全链路闭环脚本：任务拆分→PR→校验→修复→合并
# 用法：bash harness/scripts/harness-loop.sh "父需求描述" TASK_ID

PARENT_TASK="$1"
TASK_ID="$2"
HARNESS_CONFIG="harness/config.yaml"
AGENT_PROMPT="harness/prompts/agent-harness-prompt.txt"

echo "=== Starting OpenAI Harness Closed-Loop Workflow (Task: $TASK_ID) ==="

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/.."

# 设置 API Key 环境变量
export DASHSCOPE_API_KEY="sk-5912d7520b824196946131118dbd4292"

# 1. 通义灵码Quest：拆分原子子任务，生成任务清单
"$PROJECT_ROOT/lingma" quest \
  --prompt "$PARENT_TASK" \
  --config "$HARNESS_CONFIG" \
  --prompt-file "$AGENT_PROMPT" \
  --output harness/tasks/subtasks.txt

# 2. 遍历每个子任务，执行完整闭环
while IFS= read -r SUBTASK; do
  echo -e "\n=== Processing Subtask: $SUBTASK ==="
  # 创建分支
  BRANCH="feature/$TASK_ID-$(echo "$SUBTASK" | tr ' ' '-')"
  git checkout -b "$BRANCH"
  # 通义灵码Agent：开发代码+测试+提交+开PR
  "$PROJECT_ROOT/lingma" agent \
    --prompt "完成子任务：$SUBTASK，创建PR，遵守所有Harness规则" \
    --workspace . \
    --config "$HARNESS_CONFIG" \
    --prompt-file "$AGENT_PROMPT"
  # 推送分支+创建PR
  git push origin "$BRANCH"
  gh pr create \
    --title "[AI-Harness] feature: $SUBTASK (#$TASK_ID)" \
    --body-file PR_TEMPLATE.md \
    --label AI-Generated,Harness-Auto,Review-Required
  # 等待CI+自动修复循环
  RETRIES=0
  MAX_RETRIES=$(yq e '.harness.validation.max_retries' "$HARNESS_CONFIG")
  while true; do
    # 检查PR状态
    PR_STATUS=$(gh pr status | grep -E "(success|failure)" | head -1)
    if echo "$PR_STATUS" | grep -q "success"; then
      echo "✅ Subtask $SUBTASK passed, merging PR..."
      gh pr merge --merge --delete-branch
      break
    fi
    if (( RETRIES >= MAX_RETRIES )); then
      echo "❌ Max retries reached, manual intervention required"
      break
    fi
    echo "🔄 CI failed, retry $((RETRIES+1))/$MAX_RETRIES, triggering auto-repair..."
    # 调用Agent修复
    "$PROJECT_ROOT/lingma" agent \
      --prompt "修复当前PR的CI失败，严格遵守Harness规则" \
      --error-log harness/errors/ci-failure.log \
      --workspace .
    git add . && git commit -m "[AI-Harness] fix: retry $((RETRIES+1))" && git push
    ((RETRIES++))
    sleep 60
  done
done < harness/tasks/subtasks.txt

echo -e "\n=== Harness Workflow Completed for Task $TASK_ID ==="