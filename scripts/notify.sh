#!/usr/bin/env bash

set -euo pipefail

# =========================
# 检查 jq
# =========================
if ! command -v jq >/dev/null 2>&1; then
  echo "错误：未安装 jq，请先安装 jq，命令：winget install jqlang.jq" >&2
  exit 1
fi

# =========================
# 1. 判断是否有 stdin 输入
# =========================
if [ -t 0 ]; then
  INPUT=""
else
  INPUT="$(cat)"
fi

# =========================
# 2. 默认参数（兜底）
# =========================
TITLE="${1:-通知}"
MESSAGE="${2:-内容}"

# =========================
# 3. 如果有 JSON 输入 → 覆盖参数
# =========================
if [ -n "$INPUT" ]; then
  # 提取 message
  MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // "无内容"')

  # 提取 cwd → 取最后目录
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PROJECT=$(basename "$(echo "$CWD" | tr '\\' '/')")

  # 生成标题
  TITLE="claude：$PROJECT"
fi

# =========================
# 4. 转义（防止 PowerShell 炸）
# =========================
TITLE_ESC=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')
MESSAGE_ESC=$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')

# =========================
# 5. 定位 PowerShell 脚本
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT=$(cygpath -w "$SCRIPT_DIR/notify.ps1")

# =========================
# 6. 调用 PowerShell
# =========================
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "$PS_SCRIPT" \
  -Title "$TITLE_ESC" \
  -Message "$MESSAGE_ESC"