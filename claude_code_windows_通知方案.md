# 如何通过 Claude Code 发送 Windows 系统通知

## 1. 问题背景

在使用 Claude Code（带 Hook 能力）时，希望在以下场景触发本地系统通知：

- 对话结束（Stop 事件）
- 长任务执行完成
- 构建 / 脚本执行结果提醒

目标：

> 通过 Claude Code → Hook → 本地脚本 → Windows 通知，实现自动提醒链路。

---

## 2. 环境安装

在 Windows 上需要安装 PowerShell 通知模块和 jq：

```powershell
Install-Module -Name BurntToast -Force
```

```powershell
winget install jqlang.jq
```

验证：

```bash
jq --version
```

---

## 3. 总体方案

整体链路如下：

```
Claude Code
   ↓ (Hook JSON)
stdin
   ↓
notify.sh (Git Bash)
   ↓
notify.ps1 (PowerShell)
   ↓
Windows Toast Notification
```

核心组件：

- Bash：负责解析输入 + 调度
- jq：解析 JSON
- PowerShell：调用系统通知
- BurntToast：Windows Toast 封装

---

## 4. 关键实现

### 3.1 Bash 脚本（notify.sh）

功能：

- 读取 stdin JSON
- 提取字段
- 构造标题和内容
- 调用 PowerShell

```bash
#!/usr/bin/env bash

set -euo pipefail

# 检查 jq
if ! command -v jq >/dev/null 2>&1; then
  echo "错误：未安装 jq" >&2
  exit 1
fi

# 读取 stdin
if [ -t 0 ]; then
  INPUT=""
else
  INPUT="$(cat)"
fi

# 默认值
TITLE="${1:-通知}"
MESSAGE="${2:-内容}"

# 如果有 JSON 输入
if [ -n "$INPUT" ]; then
  MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // "无内容"')

  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PROJECT=$(basename "$(echo "$CWD" | tr '\\\\' '/')")

  TITLE="claude：$PROJECT"
fi

# 转义
TITLE_ESC=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')
MESSAGE_ESC=$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')

# 定位 ps1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT=$(cygpath -w "$SCRIPT_DIR/notify.ps1")

# 调用 PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "$PS_SCRIPT" \
  -Title "$TITLE_ESC" \
  -Message "$MESSAGE_ESC"
```

---

### 3.2 PowerShell 脚本（notify.ps1）

```powershell
param(
    [string]$Title = "通知",
    [string]$Message = "内容"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Import-Module BurntToast
New-BurntToastNotification -Text $Title, $Message
```

---

## 5. 输入数据结构（Claude Hook）

示例：

```json
{
  "session_id": "xxx",
  "cwd": "c:\\Users\\xxx\\project",
  "hook_event_name": "Stop",
  "last_assistant_message": "任务执行完成"
}
```

字段说明：

| 字段                   | 用途         |
| ---------------------- | ------------ |
| last_assistant_message | 通知内容     |
| cwd                    | 提取项目名   |
| hook_event_name        | 控制触发时机 |

---

## 6. 标题生成规则

```text
claude：<项目名>
```

例如：

```
cwd = c:\Users\xxx\my-skills
→ 标题：claude：my-skills
```

---

### 6.1 手动调用

```bash
./notify.sh "Hello" "World"
```

### 6.2 管道调用（推荐）

```bash
cat input.json | ./notify.sh
```

### 6.3 Hook 场景

Claude 自动触发：

```
Hook → notify.sh
```

---

## 7. 关键问题与解决

### 7.1 stdin 阻塞

问题：

```bash
INPUT=$(cat)
```

在无输入时会阻塞。

解决：

```bash
[ -t 0 ] && INPUT="" || INPUT="$(cat)"
```

---

### 7.2 Windows 路径处理

问题：

```
C:\xxx\xxx
```

basename 无法识别。

解决：

```bash
tr '\\' '/'
```

---

### 7.3 PowerShell 引号问题

问题：

- 双引号导致命令解析错误

解决：

```bash
sed 's/"/\\"/g'
```

---

### 7.4 jq 依赖

问题：

- Windows 默认没有 jq

解决：

- 使用包管理器安装
- 或项目内自带 jq.exe

---

## 8. 可选优化

### 8.1 仅 Stop 事件触发

```bash
HOOK=$(echo "$INPUT" | jq -r '.hook_event_name // ""')

if [ "$HOOK" != "Stop" ]; then
  exit 0
fi
```

---

### 8.2 性能优化

- 预安装 BurntToast
- 避免每次 Install-Module

---

### 8.3 去重 / 限流

避免通知刷屏：

- 缓存 last message
- 相同内容不重复通知

---

## 9. 总结

该方案实现了：

- Claude Code → 本地系统通知的完整链路
- Bash + PowerShell 跨环境协作
- JSON 结构化解析

特点：

- 简单
- 可扩展
- 工程可用

适用于：

- 本地开发提醒
- CI/CD 反馈
- 长任务通知

---

## 10. 后续扩展方向

- 跨平台通知（macOS / Linux）
- Webhook → 本地通知桥接
- 通知优先级（失败优先）
- 富通知（按钮 / 图片 / 进度条）
