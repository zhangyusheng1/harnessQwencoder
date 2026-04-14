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

# 检查是否已初始化 Git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  未检测到 Git 仓库，正在初始化..."
    git init
    # 创建初始提交
    git add .
    git commit -m "Initial commit for Harness workflow" --allow-empty
fi

# 检查是否配置了远程仓库
if ! git remote get-url origin &>/dev/null; then
    echo "⚠️  未配置远程仓库，请先设置:"
    echo "   git remote add origin https://github.com/your-username/your-repo.git"
    echo "   或使用 SSH: git remote add origin git@github.com:your-username/your-repo.git"
    exit 1
fi

# 获取当前分支名
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="main"
fi

echo "✅ 当前工作分支: $CURRENT_BRANCH"

# 加载 GitHub PR Helper
source "$SCRIPT_DIR/github-pr-helper.sh"

# 2. 遍历每个子任务，执行完整闭环
while IFS= read -r SUBTASK; do
  # 跳过空行
  if [ -z "$SUBTASK" ]; then
    continue
  fi
  
  echo -e "\n=== Processing Subtask: $SUBTASK ==="
  
  # 清理分支名中的特殊字符
  CLEAN_SUBTASK=$(echo "$SUBTASK" | tr ' ' '-' | tr '/' '_' | tr -cd '[:alnum:]-_')
  BRANCH="feature/$TASK_ID-$CLEAN_SUBTASK"
  
  # 创建并切换到新分支
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git checkout "$BRANCH"
    echo "🔄 切换到现有分支: $BRANCH"
  else
    git checkout -b "$BRANCH"
    echo "🆕 创建新分支: $BRANCH"
  fi
  
  # 通义灵码Agent：开发代码+测试
  "$PROJECT_ROOT/lingma" agent \
    --prompt "完成子任务：$SUBTASK，遵守所有Harness规则，包括编写单元测试" \
    --workspace . \
    --config "$HARNESS_CONFIG" \
    --prompt-file "$AGENT_PROMPT"
  
  # 提交更改
  git add .
  if ! git diff --staged --quiet 2>/dev/null; then
    git commit -m "[AI-Harness] feat: $SUBTASK (#$TASK_ID)" 
    echo "✅ 已提交更改到分支: $BRANCH"
  else
    echo "⚠️  无更改需要提交"
  fi
  
  # 推送分支并创建 PR
  PR_TITLE="[AI-Harness] feature: $SUBTASK (#$TASK_ID)"
  PR_BODY_FILE="PR_TEMPLATE.md"
  PR_BODY="完成子任务：$SUBTASK\n\n遵守所有Harness规则"
  
  if [ -f "$PR_BODY_FILE" ]; then
    PR_BODY=$(cat "$PR_BODY_FILE")
  fi
  
  # 创建 Pull Request
  if create_pull_request "$BRANCH" "$PR_TITLE" "$PR_BODY"; then
    PR_URL=$(cat "harness/pr-url.txt")
    echo "🔗 PR URL: $PR_URL"
    
    # 等待CI+自动修复循环
    RETRIES=0
    MAX_RETRIES=3
    if [ -f "$HARNESS_CONFIG" ]; then
      MAX_RETRIES=$(yq e '.harness.validation.max_retries // 3' "$HARNESS_CONFIG")
    fi
    
    while true; do
      sleep 30  # 等待 CI 状态更新
      
      PR_STATUS=$(check_pr_status "$PR_URL")
      if [ "$PR_STATUS" = "merged" ]; then
        echo "✅ Subtask $SUBTASK 已合并"
        break
      elif [ "$PR_STATUS" = "success" ]; then
        echo "✅ Subtask $SUBTASK 通过校验，正在合并..."
        if merge_pull_request "$PR_URL"; then
          break
        fi
      fi
      
      if (( RETRIES >= MAX_RETRIES )); then
        echo "❌ Max retries reached, manual intervention required"
        echo "📝 PR URL: $PR_URL"
        break
      fi
      
      echo "🔄 CI failed, retry $((RETRIES+1))/$MAX_RETRIES, triggering auto-repair..."
      
      # 调用Agent修复
      "$PROJECT_ROOT/lingma" agent \
        --prompt "修复当前PR的CI失败，严格遵守Harness规则" \
        --error-log harness/errors/ci-failure.log \
        --workspace .
        
      git add .
      if ! git diff --staged --quiet 2>/dev/null; then
        git commit -m "[AI-Harness] fix: retry $((RETRIES+1))"
        git push
      fi
      
      ((RETRIES++))
    done
  else
    echo "❌ 创建 PR 失败，跳过自动化流程"
    echo "💡 请手动推送分支并创建 PR"
  fi
  
  # 切换回主分支
  git checkout "$CURRENT_BRANCH"
done < harness/tasks/subtasks.txt

echo -e "\n=== Harness Workflow Completed for Task $TASK_ID ==="