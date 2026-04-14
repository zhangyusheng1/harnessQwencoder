#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
真实的 Lingma CLI 工具实现
支持与通义千问 Coder API 交互（使用 Qwen API Key），执行 quest 和 agent 命令
"""

import os
import sys
import json
import argparse
import requests
import yaml
from pathlib import Path

# API 配置 - 使用通义千问 Coder API（兼容 Qwen API Key）
# 根据官方文档：https://help.aliyun.com/zh/model-studio/qwen-coder
API_BASE_URL = "https://dashscope.aliyuncs.com/api/v1"
MODEL_NAME = "qwen3-coder-plus"  # 追求极致质量的代码模型

def load_config(config_path=None):
    """加载配置文件"""
    config = {}
    # 优先使用 DASHSCOPE_API_KEY（官方推荐），回退到 LINGMA_API_KEY
    config['api_key'] = os.getenv('DASHSCOPE_API_KEY') or os.getenv('LINGMA_API_KEY')
    config['workspace'] = os.getenv('LINGMA_WORKSPACE_ID', '.')
    
    secrets_path = os.getenv('MCP_SECRETS_PATH', 'config/secrets/mcp-secrets.yaml')
    if os.path.exists(secrets_path):
        with open(secrets_path, 'r', encoding='utf-8') as f:
            secrets = yaml.safe_load(f)
            if secrets and 'lingma' in secrets:
                config['api_key'] = secrets['lingma'].get('api_key', config['api_key'])
    
    return config

def call_lingma_api(prompt, config, error_log=None):
    """调用通义千问 Coder API（使用 Qwen API Key）"""
    if not config.get('api_key'):
        print("错误: 未找到 API Key，请在 .env 或 config/secrets/mcp-secrets.yaml 中配置 DASHSCOPE_API_KEY 或 LINGMA_API_KEY", file=sys.stderr)
        sys.exit(1)
    
    headers = {
        'Authorization': f'Bearer {config["api_key"]}',
        'Content-Type': 'application/json'
    }
    
    # 构建请求体 - DashScope 原生 API 格式（根据官方文档）
    payload = {
        "model": MODEL_NAME,
        "input": {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ]
        },
        "parameters": {
            "result_format": "message"
        }
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/services/aigc/text-generation/generation",
            headers=headers,
            json=payload,
            timeout=300
        )
        
        if response.status_code == 200:
            result = response.json()
            return result['output']['choices'][0]['message']['content']
        else:
            print(f"API 调用失败: {response.status_code} - {response.text}", file=sys.stderr)
            return None
            
    except Exception as e:
        print(f"API 调用异常: {str(e)}", file=sys.stderr)
        return None

def handle_quest(args):
    """处理 quest 命令"""
    print("执行 Lingma Quest: 任务拆分")
    
    config = load_config()
    prompt = f"你是一个专业的软件开发助手。请将以下需求拆分为原子子任务，每个子任务应该独立、可执行，且不超过500行代码：\n\n{args.prompt}"
    
    result = call_lingma_api(prompt, config)
    if result:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        tasks = []
        if "1." in result or "- " in result:
            lines = result.split('\n')
            for line in lines:
                if line.strip() and (line.strip().startswith('1.') or line.strip().startswith('- ') or line.strip()[0].isdigit()):
                    task = line.strip().split('.', 1)[-1].split('-', 1)[-1].strip()
                    if task:
                        tasks.append(task)
        
        if not tasks:
            tasks = [f"实现需求: {args.prompt[:100]}..."]
        
        with open(output_path, 'w', encoding='utf-8') as f:
            for task in tasks:
                f.write(f"{task}\n")
        
        print(f"Quest 完成。子任务已写入: {output_path}")
    else:
        print("Quest 失败，请检查 API 配置和网络连接", file=sys.stderr)
        sys.exit(1)

def handle_agent(args):
    """处理 agent 命令"""
    print("执行 Lingma Agent: 代码生成")
    
    config = load_config()
    
    full_prompt = args.prompt
    if args.error_log and os.path.exists(args.error_log):
        with open(args.error_log, 'r', encoding='utf-8') as f:
            error_content = f.read()
        full_prompt += f"\n\n错误日志:\n{error_content}"
    
    if args.workspace:
        full_prompt += f"\n\n工作区路径: {args.workspace}"
    
    result = call_lingma_api(full_prompt, config)
    if result:
        print("Agent 执行完成")
        print("生成的内容:")
        print(result)
    else:
        print("Agent 执行失败，请检查 API 配置和网络连接", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: lingma <command> [options]")
        print("Available commands: quest, agent")
        sys.exit(1)
    
    command = sys.argv[1]
    remaining_args = sys.argv[2:]
    
    if command == "quest":
        parser = argparse.ArgumentParser(description="Lingma Quest - 任务拆分")
        parser.add_argument("--prompt", required=True, help="父任务描述")
        parser.add_argument("--config", help="配置文件路径")
        parser.add_argument("--prompt-file", help="提示词文件路径")
        parser.add_argument("--output", required=True, help="输出文件路径")
        
        args = parser.parse_args(remaining_args)
        handle_quest(args)
        
    elif command == "agent":
        parser = argparse.ArgumentParser(description="Lingma Agent - 代码生成")
        parser.add_argument("--prompt", required=True, help="任务描述")
        parser.add_argument("--workspace", help="工作区路径")
        parser.add_argument("--config", help="配置文件路径")
        parser.add_argument("--prompt-file", help="提示词文件路径")
        parser.add_argument("--error-log", help="错误日志文件路径")
        
        args = parser.parse_args(remaining_args)
        handle_agent(args)
        
    else:
        print(f"未知命令: {command}")
        print("可用命令: quest, agent")
        sys.exit(1)

if __name__ == "__main__":
    main()