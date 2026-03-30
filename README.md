# Claude Code 个人配置库

围绕 Claude Code / OpenClaw 的 Agent 实验项目，包含配置、脚本、工程原则和最佳实践。

## 目录结构

```
my-skills/
├── docs/
│   ├── getting-started/      # 入门指南
│   ├── guides/               # 使用指南
│   │   ├── advanced/         # 高级主题
│   │   ├── hooks/            # Hook 配置
│   │   └── workflow/         # 工作流
│   └── reference/            # 参考资料
├── scripts/                  # 脚本
│   ├── hooks/                # Hook 脚本
│   └── notifications/        # 通知脚本
└── .claude/                  # Claude Code 配置
```

## 快速导航

| 类别 | 内容 |
|------|------|
| [安装指南](docs/getting-started/installation/windows-Claude-Code-install.md) | Windows 环境配置 |
| [Hooks 配置](docs/guides/hooks/Hooks配置指南.md) | 钩子脚本编写 |
| [工作流](docs/guides/workflow/) | 并行开发、Worktree、VSCode 集成 |
| [工程原则](docs/guides/advanced/Agent三定律.md) | Skills-First、Design-Before-Code |

## 主要特性

### Claude Code 集成

- **权限管理**：预配置允许的命令（git、pnpm、curl），保护 .env 文件
- **执行钩子**：Bash 和 Edit 操作执行前输出提示
- **遥测禁用**：关闭数据收集以保护隐私

### 工程原则

- Skills-First 问题解决方法
- Design-Before-Implementation 流程
- 结构化、精确的沟通风格

## Changelog

| 日期       | 更新内容                                            |
| ---------- | --------------------------------------------------- |
| 2026-03-21 | chore: 重构目录架构，文档分类整理                   |
| 2026-02-03 | feat: 添加代码审查Agent并更新权限配置               |

## 配置参考

### 配置与权限
- [命令分类与权限控制模型](docs/reference/claude-code-commands.md) - 内置命令的五类抽象与权限配置
- [settings.json 配置](https://code.claude.com/docs/en/settings#settings-files)
- [Subagent configuration](https://code.claude.com/docs/en/settings#subagent-configuration)
- [自定义子代理](https://code.claude.com/docs/en/sub-agents#work-with-subagents)

### Hooks
- [hook matcher 语法](https://code.claude.com/docs/en/hooks#matcher-patterns)
- [hook 脚本的语法与输入参数](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)
- [hook 读取输入返回输出给 claude](https://code.claude.com/docs/en/hooks-guide#read-input-and-return-output)
- [可复用的 hooks 存放目录`.claude/hooks`](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)

### 工作流
- [使用 Git Worktrees 运行多个并行的 Claude Code 会话](https://code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees)

### MCP
- [通过 MCP 将 Claude 与工具连接起来](https://code.claude.com/docs/en/mcp)
- [Claude Code skills](https://code.claude.com/docs/en/skills)

### 其他
- [Using CLAUDE.md files](https://claude.com/blog/using-claude-md-files)
- [系统提示词（System prompt）](https://code.claude.com/docs/en/settings#system-prompt)
- [命令行参数（CLI flags）](https://code.claude.com/docs/en/cli-reference#cli-flags)

### 记忆
- [CLAUDE.md 记忆](https://code.claude.com/docs/en/memory#claude-md-vs-auto-memory)
