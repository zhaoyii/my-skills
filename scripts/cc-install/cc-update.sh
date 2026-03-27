#!/bin/bash

# ==========================================
# Claude Code 更新脚本
# ==========================================

# 1. 加载代理配置
if [ -f ~/.proxy.env ]; then
    source ~/.proxy.env
    echo -e "\033[36m已加载代理配置\033[0m"
fi

# 2. 执行更新
echo -e "\033[32m正在更新 Claude Code...\033[0m"

claude update

# 3. 验证更新结果
echo -e "\n\033[36m--- 验证更新结果 ---\033[0m"
if command -v claude &> /dev/null; then
    claude --version
    echo -e "\033[32m更新成功！\033[0m"
else
    echo -e "\033[31m未能找到 claude 命令，请检查安装状态。\033[0m"
fi
