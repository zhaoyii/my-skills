# 我的技能仓库

个人技能文档库，记录工程原则、AI 协作指南和开发配置。

## 文件说明

| 文件/目录                                      | 说明                                 |
| ---------------------------------------------- | ------------------------------------ |
| [CLAUDE_BASE.md](CLAUDE_BASE.md)               | Claude Code Agent 行为基准准则       |
| [.claude/](.claude/)                           | Claude Code 配置目录                 |
| [.claude/settings.json](.claude/settings.json) | Claude Code 配置（权限、钩子、遥测） |
| [.claude/skills/](.claude/skills/)             | 技能定义目录                         |
| [.claude/HOOKS_GUIDE.md](.claude/HOOKS_GUIDE.md) | Hook 配置指南                        |

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
| 2026-02-03 | feat: 添加代码审查Agent并更新权限配置               |
| 2026-02-03 | docs: 重构并简化Agent基础元指令文档                 |
| 2026-02-03 | chore: 将默认权限模式从auto改为default              |
| 2026-01-29 | docs: 更新 README 为中文版本，添加 Claude Code 配置 |
| 2026-01-29 | docs: 添加CLAUDE基础工作准则文档                    |

## mcp 安装

**目前最稳妥的方式是通过 CLI 安装。**

```
claude mcp add -s user MiniMax --env MINIMAX_API_KEY=api_key --env MINIMAX_API_HOST=https://api.minimaxi.com -- uvx minimax-coding-plan-mcp -y
```

## Claude Code 配置参考

- [Using CLAUDE.md files: Customizing Claude Code for your codebase](https://claude.com/blog/using-claude-md-files)
- [系统提示词（System prompt）](https://code.claude.com/docs/en/settings#system-prompt)
- [命令行参数（CLI flags）](https://code.claude.com/docs/en/cli-reference#cli-flags)
- [CLAUDE.md configuration 是什么](https://code.claude.com/docs/en/gitlab-ci-cd#claude-md-configuration)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
  - [settings.json 配置](https://code.claude.com/docs/en/settings#settings-files)
  - [Subagent configuration](https://code.claude.com/docs/en/settings#subagent-configuration)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [通过 MCP 将 Claude 与工具连接起来](https://code.claude.com/docs/en/mcp)
- [Minimax 的 Coding Plan MCP：web_search 和 understand_image](https://platform.minimaxi.com/docs/guides/coding-plan-mcp-guide#web-search)
- [自定义子代理](https://code.claude.com/docs/en/sub-agents#work-with-subagents)
- [使用 Git Worktrees 运行多个并行的 Claude Code 会话](https://code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees)
- [hook matcher 语法](https://code.claude.com/docs/en/hooks#matcher-patterns)
- [hook 脚本的语法与输入参数](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)
- [hook 读取输入返回输出给 claude](https://code.claude.com/docs/en/hooks-guide#read-input-and-return-output)
