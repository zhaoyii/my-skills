# 使用 Git Worktrees 运行多个并行的 Claude Code 会话

当你同时处理多个任务时，需要让每个 Claude
会话拥有**独立的代码副本**，这样不同任务的修改就不会互相冲突。

**Git worktree** 可以解决这个问题：\
它会创建 **多个独立的工作目录（working
directories）**，每个目录都有自己的文件和分支，但
**共享同一个仓库的历史记录和远程连接**。

这意味着你可以：

- 让 **一个 Claude 在某个 worktree 中开发新功能**
- 同时让 **另一个 Claude 在另一个 worktree 中修复 bug**
- 两个会话互不干扰

---

# 使用方法

使用 `--worktree`（或 `-w`）参数创建一个隔离的 worktree，并在其中启动
Claude。

你传入的参数值会同时作为：

- **worktree 目录名**
- **分支名**

示例：

```bash
# 在名为 "feature-auth" 的 worktree 中启动 Claude
# 会创建 .claude/worktrees/feature-auth/ 并新建一个分支
claude --worktree feature-auth

# 在另一个 worktree 中启动一个新的会话
claude --worktree bugfix-123
```

---

# 自动生成名称

如果你不指定名称，Claude 会自动生成一个随机名字：

```bash
# 自动生成类似 "bright-running-fox" 的名称
claude --worktree
```

---

# Worktree 目录结构

创建的 worktree 位于：

    <repo>/.claude/worktrees/<name>

特点：

- 从 **默认远程分支（default remote branch）** 创建
- 对应的分支名称为：

```{=html}
<!-- -->
```

    worktree-<name>

---

# 在会话中创建 Worktree

你也可以在 Claude 会话中直接说：

- `work in a worktree`
- `start a worktree`

Claude 会自动为你创建并切换到新的 worktree。

---

# 重要说明

**Git worktree 并不会复制整个仓库。**

它只是创建新的工作目录，并共享同一个 `.git` 对象库，因此：

- 占用空间非常小
- 创建速度非常快
- 非常适合 **AI Agent / Claude Code 并行开发**
