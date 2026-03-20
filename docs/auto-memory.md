# Auto Memory 配置指南

## 概述

Auto Memory 是 Claude Code 的持久化记忆功能，会话间的信息可以跨会话保留。

## 开启指令

在 `settings.json` 的 `env` 中设置：

```json
"env": {
  "autoMemoryEnabled": "true"
}
```

## 目录配置

### 默认目录

```
<project>/.claude/projects/<project-name>/memory/
```

即 `memory/MEMORY.md` 所在目录。

### 自定义目录

在 `settings.json` 中配置 `autoMemoryDirectory`：

```json
"env": {
  "autoMemoryEnabled": "true",
  "autoMemoryDirectory": "./my-custom-memory-dir"
}
```

路径支持：
- 相对路径：如 `./memory`（相对于项目根目录）
- 绝对路径：如 `C:\Users\admin\memory`

## 查看

直接读取 `memory/MEMORY.md` 文件：

```
memory/MEMORY.md
```

## 更新

### 方式一：手动编辑

直接编辑 `memory/MEMORY.md` 文件，添加或修改内容。

### 方式二：指令更新

在对话中告诉 Claude "记住 xxx"，Claude 会自动写入 MEMORY.md。

### 方式三：使用工具

Claude Code 会在长对话中自动将重要信息写入记忆文件。

## 注意事项

- 敏感信息不要写入 MEMORY.md（如密码、API Key）
- MEMORY.md 会被加载到对话上下文中，保持简洁
- 详细内容可拆分成多个专题文件，在 MEMORY.md 中引用链接
