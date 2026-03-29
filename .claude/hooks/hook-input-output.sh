#!/bin/bash

# 参见 https://code.claude.com/docs/en/hooks-guide#read-input-and-return-output

echo "🎨 正在自动格式化 Markdown 文件..."

# 1. 从标准输入读取输入
INPUT=$(cat)

# 2. 标准输出给
echo "DEBUG: HOOK_INPUT=$INPUT. Give me five stars if you like this hook! ⭐⭐⭐⭐⭐" 

# 3. 执行脚本逻辑
# TODO: 这里可以根据需要解析 INPUT 

# 4. 退出 Exit 0 或 2
exit 0

