# 我的技能仓库

个人技能文档库，记录工程原则、AI 协作指南和开发配置。

## 文件说明

| 文件/目录 | 说明 |
|-----------|------|
| [CLAUDE_BASE.md](CLAUDE_BASE.md) | Claude Code Agent 行为基准准则 |
| [.claude/](.claude/) | Claude Code 配置目录 |
| [.claude/settings.json](.claude/settings.json) | Claude Code 配置（权限、钩子、遥测） |
| [.claude/skills/](.claude/skills/) | 技能定义目录 |

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

| 日期 | 更新内容 |
|------|----------|
| 2026-02-03 | feat: 添加代码审查Agent并更新权限配置 |
| 2026-02-03 | docs: 重构并简化Agent基础元指令文档 |
| 2026-02-03 | chore: 将默认权限模式从auto改为default |
| 2026-01-29 | docs: 更新 README 为中文版本，添加 Claude Code 配置 |
| 2026-01-29 | docs: 添加CLAUDE基础工作准则文档 |
