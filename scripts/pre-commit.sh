#!/bin/bash

echo "🎨 正在自动格式化 Markdown 文件..."

INPUT=$(cat)

# 0. 调试：打印 CLU_TOOL_ARGS 和所有环境变量
echo "DEBUG: CLU_TOOL_ARGS=[$CLU_TOOL_ARGS]"
echo "DEBUG: CLAUDE_TOOL_INPUT=$CLAUDE_TOOL_INPUT"
echo "DEBUG: CLAUDE---INPUT=$INPUT"

# 1. 检查是否是 diff 操作
if [[ ! "$CLU_TOOL_ARGS" =~ "diff" ]]; then
  echo "⚠️  不是 diff 操作，跳过格式化"
  exit 0
fi

# 3. 执行格式化
npx prettier --write ./**\*.md

# 4. 将格式化后的改动重新加入暂存区
git add --all

echo "✅ 格式化完成"