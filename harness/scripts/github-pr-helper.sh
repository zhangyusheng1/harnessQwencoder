#!/bin/bash
# GitHub PR Helper - 使用原生 Git 和 GitHub API 实现 PR 自动化
# 无需 gh CLI，只需要 GitHub Personal Access Token

set -e

# 配置文件路径
GITHUB_CONFIG_FILE=".github-config"

# 函数：获取 GitHub 配置
get_github_config() {
    if [ -f "$GITHUB_CONFIG_FILE" ]; then
        source "$GITHUB_CONFIG_FILE"
    fi
    
    # 如果没有配置文件，提示用户输入
    if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO" ]; then
        echo "⚠️  GitHub 配置未找到，请提供以下信息："
        echo ""
        
        # 获取 GitHub Token
        if [ -z "$GITHUB_TOKEN" ]; then
            read -p "请输入 GitHub Personal Access Token: " GITHUB_TOKEN
            echo "GITHUB_TOKEN='$GITHUB_TOKEN'" >> "$GITHUB_CONFIG_FILE"
        fi
        
        # 获取仓库信息
        if [ -z "$GITHUB_REPO" ]; then
            # 尝试从 git remote 获取
            if git remote get-url origin &>/dev/null; then
                REMOTE_URL=$(git remote get-url origin)
                # 提取 owner/repo 格式
                if [[ $REMOTE_URL == *"github.com"* ]]; then
                    # 处理 https://github.com/owner/repo.git 格式
                    if [[ $REMOTE_URL == https* ]]; then
                        GITHUB_REPO=$(echo "$REMOTE_URL" | sed 's/https:\/\/github.com\///' | sed 's/\.git$//')
                    # 处理 git@github.com:owner/repo.git 格式
                    elif [[ $REMOTE_URL == git@* ]]; then
                        GITHUB_REPO=$(echo "$REMOTE_URL" | sed 's/git@github.com://' | sed 's/\.git$//')
                    fi
                fi
            fi
            
            if [ -z "$GITHUB_REPO" ]; then
                read -p "请输入 GitHub 仓库 (格式: owner/repo): " GITHUB_REPO
            fi
            echo "GITHUB_REPO='$GITHUB_REPO'" >> "$GITHUB_CONFIG_FILE"
        fi
        
        echo ""
        echo "✅ GitHub 配置已保存到 .github-config"
        echo "💡 注意: .github-config 已加入 .gitignore，不会被提交"
    fi
}

# 函数：创建 Pull Request
create_pull_request() {
    local branch="$1"
    local title="$2"
    local body="$3"
    
    get_github_config
    
    # 推送分支
    echo "📤 推送分支到 GitHub..."
    git push -u origin "$branch"
    
    # 创建 PR 的 API 请求体
    PR_DATA=$(cat <<EOF
{
    "title": "$title",
    "body": "$body",
    "head": "$branch",
    "base": "$(git branch --show-current)"
}
EOF
)
    
    echo "📝 创建 Pull Request..."
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$PR_DATA" \
        "https://api.github.com/repos/$GITHUB_REPO/pulls")
    
    # 检查是否成功
    if echo "$RESPONSE" | grep -q '"html_url"'; then
        PR_URL=$(echo "$RESPONSE" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        echo "✅ Pull Request 创建成功: $PR_URL"
        echo "$PR_URL" > "harness/pr-url.txt"
    else
        echo "❌ 创建 Pull Request 失败:"
        echo "$RESPONSE"
        return 1
    fi
}

# 函数：检查 PR 状态
check_pr_status() {
    local pr_url="$1"
    
    get_github_config
    
    # 从 URL 提取 PR 编号
    PR_NUMBER=$(echo "$pr_url" | grep -o '/pull/[0-9]*' | cut -d'/' -f3)
    
    RESPONSE=$(curl -s -X GET \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPO/pulls/$PR_NUMBER")
    
    STATUS=$(echo "$RESPONSE" | grep -o '"state":"[^"]*"' | cut -d'"' -f4)
    MERGEABLE=$(echo "$RESPONSE" | grep -o '"mergeable":true')
    
    if [ "$STATUS" = "closed" ]; then
        echo "merged"
    elif [ -n "$MERGEABLE" ]; then
        echo "success"
    else
        echo "pending"
    fi
}

# 函数：合并 PR
merge_pull_request() {
    local pr_url="$1"
    
    get_github_config
    
    PR_NUMBER=$(echo "$pr_url" | grep -o '/pull/[0-9]*' | cut -d'/' -f3)
    
    MERGE_DATA='{"merge_method":"merge"}'
    
    RESPONSE=$(curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$MERGE_DATA" \
        "https://api.github.com/repos/$GITHUB_REPO/pulls/$PR_NUMBER/merge")
    
    if echo "$RESPONSE" | grep -q '"merged":true'; then
        echo "✅ PR 已成功合并"
        return 0
    else
        echo "❌ 合并 PR 失败:"
        echo "$RESPONSE"
        return 1
    fi
}

# 主函数 - 根据参数调用相应功能
main() {
    case "$1" in
        "create")
            create_pull_request "$2" "$3" "$4"
            ;;
        "check")
            check_pr_status "$2"
            ;;
        "merge")
            merge_pull_request "$2"
            ;;
        *)
            echo "用法: $0 {create|check|merge} [参数...]"
            echo "  create <branch> <title> <body>"
            echo "  check <pr_url>"
            echo "  merge <pr_url>"
            exit 1
            ;;
    esac
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi