#!/bin/bash

echo "🎨 正在自动格式化 Markdown 文件..."

# 3. 执行格式化
npx prettier --write ./**\*.md

# 4. 将格式化后的改动重新加入暂存区
git add --all

echo "✅ 格式化完成"