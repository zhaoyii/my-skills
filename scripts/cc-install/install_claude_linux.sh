#!/bin/bash

# ==========================================
# Claude Code Linux/macOS 一键安装脚本 (10808 代理版)
# ==========================================

# 1. 设置环境变量代理
export HTTP_PROXY="http://192.168.80.1:10808"
export HTTPS_PROXY="http://192.168.80.1:10808"

echo -e "\033[36m已设置代理为: $HTTPS_PROXY\033[0m"

# 2. 使用 curl 执行安装
# -f: 失败时不显示错误页; -s: 静默模式; -L: 跟随重定向; -k: 允许不安全的 SSL 连接（应对证书报错）
echo -e "\033[32m正在从 Claude.ai 下载并运行安装脚本...\033[0m"

curl -fsSLk https://claude.ai/install.sh | bash

# 3. 验证安装
echo -e "\n\033[36m--- 验证安装结果 ---\033[0m"
if command -v claude &> /dev/null; then
    claude --version
    echo -e "\033[32m安装成功！\033[0m"
else
    echo -e "\033[31m未能找到 claude 命令，请尝试重启终端或检查 PATH 变量。\033[0m"
fi