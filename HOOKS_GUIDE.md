# Claude Code Hooks 配置指南

## 概述

Hook 是在 Claude Code 执行工具（Tool）前后的回调机制，主要用于：
- **执行前提醒/拦截** - 提醒用户即将执行的操作
- **执行后通知** - 记录操作完成
- **返回输出（辅助功能）** - 通过 stdout/stderr 返回结构化数据

> **注意**：Hook 的核心作用是**执行前提醒/拦截**，返回输出是辅助功能。

---

## Hook 配置结构

```json
{
  "hooks": {
    "PreToolUse": [...],   // 工具执行前触发
    "PostToolUse": [...],  // 工具执行后触发
    "Notification": [...]   // 通知触发
  }
}
```

### 完整配置示例

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "bash ./scripts/my-hook.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Matcher 模式

| 模式 | 匹配范围 |
|------|---------|
| `*` | 匹配所有工具 |
| `Read` | 匹配特定工具（如 Read、Edit、Bash） |
| `Read\|Edit` | 匹配多个工具（用 `\|` 分隔） |

### 常用工具名称

- `Read` - 读取文件
- `Edit` - 编辑文件
- `Write` - 写入文件
- `Bash` - 执行命令
- `Grep` - 搜索内容
- `Glob` - 文件匹配
- `WebFetch` - 网络请求
- `WebSearch` - 网络搜索
- `TodoWrite` - 任务管理
- `Agent` - 启动子代理

---

## Hook 输入数据结构

当 Hook 触发时，Claude Code 会通过 **stdin** 传递结构化的 JSON 数据：

```json
{
  "session_id": "a2e0da47-5e1e-4ded-95ff-c8bfe58db7ac",
  "transcript_path": "C:\\Users\\admin\\.claude\\projects\\...\\a2e0da47-5e1e-4ded-95ff-c8bfe58db7ac.jsonl",
  "cwd": "c:\\Users\\admin\\Documents\\GitHub\\my-skills",
  "permission_mode": "acceptedEdits",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "c:\\Users\\admin\\Documents\\GitHub\\my-skills\\README.md"
  },
  "tool_use_id": "call_function_ybn637g0pnkp_1"
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `session_id` | string | 当前会话 ID |
| `transcript_path` | string | 会话记录文件路径 |
| `cwd` | string | 当前工作目录 |
| `permission_mode` | string | 权限模式（如 `acceptedEdits`） |
| `hook_event_name` | string | 事件名称：`PreToolUse`、`PostToolUse`、`Notification` |
| `tool_name` | string | 工具名称（如 `Read`、`Bash`、`Edit`） |
| `tool_input` | object | 工具输入参数（根据工具类型不同） |
| `tool_use_id` | string | 工具调用 ID |

---

## Hook 输出

### stdout 返回

Hook 脚本通过 **stdout** 返回内容。返回的数据会被 Claude 处理：

```bash
#!/bin/bash
INPUT=$(cat)  # 读取 stdin

# 处理逻辑...

# 输出给 Claude
echo "🎨 正在格式化文件..."
echo "DEBUG: HOOK_INPUT=$INPUT"

exit 0  # 退出码：0=成功，2=拦截
```

### 退出码

| 退出码 | 行为 |
|--------|------|
| `0` | 继续执行工具 |
| `2` | 拦截工具执行 |

### 输出限制

- stdout 会被 Claude 捕获并处理
- 建议输出简洁的提示信息
- 大量数据输出可能影响性能

---

## 实际使用场景

### 1. 执行前提醒

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "echo '即将执行 Bash 命令，请确认操作安全.'"
    }
  ]
}
```

### 2. 敏感文件保护

```json
{
  "matcher": "Read",
  "hooks": [
    {
      "type": "command",
      "command": "bash ./scripts/check-sensitive.sh"
    }
  ]
}
```

### 3. 格式化触发

```json
{
  "matcher": "Edit",
  "hooks": [
    {
      "type": "command",
      "command": "bash ./scripts/format-after-edit.sh"
    }
  ]
}
```

### 4. 拦截危险操作

```bash
#!/bin/bash
INPUT=$(cat)
echo "$INPUT" | grep -q "rm -rf"
if [ $? -eq 0 ]; then
    echo "⚠️ 危险命令已被拦截！"
    exit 2  # 退出码 2 = 拦截
fi
exit 0
```

---

## 钩子脚本模板

### 基础模板

```bash
#!/bin/bash

# 1. 读取 stdin 中的结构化输入
INPUT=$(cat)

# 2. 解析输入（提取有用信息）
echo "$INPUT" | jq -r '.tool_name'  # 获取工具名称
echo "$INPUT" | jq -r '.tool_input'  # 获取工具输入

# 3. 执行逻辑
echo "🎯 工具执行前检查..."

# 4. 返回输出（可选）
echo "✅ 检查完成"

# 5. 退出：0=继续，2=拦截
exit 0
```

### 完整示例：check-sensitive.sh

```bash
#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 检查敏感文件
if echo "$FILE_PATH" | grep -qE "(\.env|\.password|credentials)"; then
    echo "⚠️ 警告：尝试访问敏感文件: $FILE_PATH"
    echo "已记录此次访问请求。"
fi

echo "🔍 已检查文件: $FILE_PATH"
exit 0
```

---

## 最佳实践

1. **保持简洁** - Hook 应快速执行，避免耗时操作
2. **错误处理** - 脚本应有错误处理，返回有意义的退出码
3. **日志记录** - 关键操作应记录日志便于审计
4. **权限最小化** - 只对必要的工具配置 Hook
5. **区分 Pre/Post** - Pre 用于提醒/拦截，Post 用于通知

---

## 相关文档

- [Hook Matcher 语法](https://code.claude.com/docs/en/hooks#matcher-patterns)
- [Hook 脚本语法与输入参数](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)
- [Hook 读取输入返回输出](https://code.claude.com/docs/en/hooks-guide#read-input-and-return-output)