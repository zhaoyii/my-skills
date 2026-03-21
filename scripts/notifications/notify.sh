#!/usr/bin/env bash

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "错误：未安装 jq，请先安装 jq，命令：winget install jqlang.jq" >&2
  exit 1
fi

if [ -t 0 ]; then
  INPUT=""
else
  INPUT="$(cat)"
fi

# =========================
# 默认参数（兜底）
# =========================
TITLE="${1:-通知}"
MESSAGE="${2:-内容}"

# =========================
# 如果有 JSON 输入 → 覆盖参数
# =========================
if [ -n "$INPUT" ]; then
  # 提取 hook_event_name
  HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')

  # 提取 cwd → 取最后目录
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PROJECT=$(basename "$(echo "$CWD" | tr '\\' '/')")

  case "$HOOK_EVENT" in
    "PermissionRequest")
      TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "未知工具"')
      TITLE="权限请求：$TOOL_NAME"

      # 从 permission_suggestions 提取建议
      SUGGESTION=$(echo "$INPUT" | jq -r '.permission_suggestions[0].behavior // ""')
      case "$SUGGESTION" in
        "allow") SUGGESTION_TEXT="建议: 添加规则允许 $TOOL_NAME" ;;
        "deny") SUGGESTION_TEXT="建议: 拒绝 $TOOL_NAME" ;;
        *) SUGGESTION_TEXT="需要处理权限请求" ;;
      esac
      MESSAGE="$SUGGESTION_TEXT"
      ;;

    "Stop")
      TITLE="会话已结束"
      LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')
      STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // ""')
      if [ -n "$STOP_REASON" ] && [ "$STOP_REASON" != "null" ]; then
        MESSAGE="停止原因: $STOP_REASON"
        [ -n "$LAST_MSG" ] && MESSAGE="$MESSAGE"$'\n'"$LAST_MSG"
      elif [ -n "$LAST_MSG" ]; then
        MESSAGE="$LAST_MSG"
      else
        MESSAGE="会话已正常结束"
      fi
      ;;

    *)
      # 默认行为
      MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // "无内容"')
      TITLE="claude：$PROJECT"
      ;;
  esac
fi

# =========================
# 转义（防止 PowerShell 炸）
# =========================
TITLE_ESC=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')
MESSAGE_ESC=$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')

# =========================
# 定位 PowerShell 脚本
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT=$(cygpath -w "$SCRIPT_DIR/notify.ps1")

# =========================
# 调用 PowerShell
# =========================
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "$PS_SCRIPT" \
  -Title "$TITLE_ESC" \
  -Message "$MESSAGE_ESC"
