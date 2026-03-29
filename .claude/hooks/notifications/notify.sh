#!/usr/bin/env bash
#
# notify.sh — Windows 通知脚本（支持 Git Bash / WSL2 / MSYS）
#
# 用法：
#   ./notify.sh "标题" "内容"                    # 直接调用
#   cat json | ./notify.sh                      # 接收 Claude hook JSON 输入
#
# 支持环境：
#   - Git Bash / Cygwin：自动调用 PowerShell 发送通知
#   - WSL2：自动转换路径后调用 PowerShell
#   - MSYS：直接调用 PowerShell
#
# 依赖：jq（Windows: winget install jqlang.jq）
#
# Claude Code Hook 配置示例（settings.json）：
#   "hooks": {
#     "Notify": "bash /path/to/scripts/notifications/notify.sh"
#   }
#
# 自定义图标：修改 ICON_REL 变量指向对应图片路径
#
set -e

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
# 定位 PowerShell 脚本 + 路径转换
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检测运行环境：WSL2 / Cygwin(Git Bash) / MSYS / 普通 Linux
detect_environment() {
  if grep -qi 'microsoft\|wsl' /proc/version 2>/dev/null; then
    echo "wsl"
  elif command -v cygpath >/dev/null 2>&1; then
    echo "cygwin"
  elif command -v msys_path >/dev/null 2>&1; then
    echo "msys"
  else
    echo "linux"
  fi
}

ENV=$(detect_environment)

case "$ENV" in
  wsl)
    # WSL2：使用 wslpath 转换路径
    WIN_SCRIPT_DIR=$(wslpath -w "$SCRIPT_DIR")
    PS_SCRIPT="$WIN_SCRIPT_DIR\\notify.ps1"
    ;;
  cygwin)
    # Git Bash / Cygwin：使用 cygpath 转换路径
    PS_SCRIPT=$(cygpath -w "$SCRIPT_DIR/notify.ps1")
    ;;
  msys)
    # MSYS：使用原生路径
    PS_SCRIPT="$SCRIPT_DIR/notify.ps1"
    ;;
  linux)
    echo "错误：当前环境不支持直接调用 PowerShell，请使用 WSL2 或安装 PowerShell" >&2
    exit 1
    ;;
esac

# =========================
# 图标路径（WSL2 转 Windows 路径）
# =========================
ICON_REL="dog.png"
ICON_PATH="$SCRIPT_DIR/$ICON_REL"

# 图标路径转换（各环境各自处理）
case "$ENV" in
  wsl)
    ICON_WIN=$(wslpath -w "$ICON_PATH" 2>/dev/null || echo "")
    ;;
  cygwin)
    ICON_WIN=$(cygpath -w "$ICON_PATH" 2>/dev/null || echo "")
    ;;
  msys)
    ICON_WIN="$ICON_PATH"
    ;;
  *)
    ICON_WIN=""
    ;;
esac

# =========================
# 调用 PowerShell
# =========================
if [ -n "$ICON_WIN" ] && [ -f "$ICON_PATH" ]; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$PS_SCRIPT" \
    -Title "$TITLE_ESC" \
    -Message "$MESSAGE_ESC" \
    -Icon "$ICON_WIN"
else
  powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$PS_SCRIPT" \
    -Title "$TITLE_ESC" \
    -Message "$MESSAGE_ESC"
fi
