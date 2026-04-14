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