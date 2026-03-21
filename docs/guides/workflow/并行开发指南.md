# Claude Code 并行开发指南

当你同时处理多个任务时，需要让每个 Claude 会话拥有**独立的代码副本**，这样不同任务的修改就不会互相冲突。

**Git worktree** 可以解决这个问题。它会创建 **多个独立的工作目录（working directories）**，每个目录都有自己的文件和分支，但**共享同一个仓库的历史记录和远程连接**。

这意味着你可以：

- 让 **一个 Claude 在某个 worktree 中开发新功能**
- 同时让 **另一个 Claude 在另一个 worktree 中修复 bug**
- 两个会话互不干扰

---

## 方法一：使用 claude --worktree（推荐）

Claude Code 内置了 `--worktree` 参数，可以自动完成以下操作：

1. 创建 worktree 目录（位于 `.claude/worktrees/<name>`）
2. 创建对应的分支
3. 自动切换到新目录并启动 Claude

### 基本用法

```bash
# 在名为 "feature-auth" 的 worktree 中启动 Claude
# 会自动创建 .claude/worktrees/feature-auth/ 并新建分支
claude --worktree feature-auth

# 在另一个 worktree 中启动另一个会话
claude --worktree bugfix-123
```

### 自动生成名称

如果不指定名称，Claude 会自动生成一个随机名字：

```bash
# 自动生成类似 "bright-running-fox" 的名称
claude --worktree
```

### 在会话中创建 Worktree

你也可以在 Claude 会话中直接说：

- `work in a worktree`
- `start a worktree`

Claude 会自动为你创建并切换到新的 worktree。

### 完整工作流程

1. **创建 worktree 并启动 Claude**

   ```bash
   claude --worktree feature-auth
   ```

2. **在 worktree 中开发代码**
   - 让 Claude 修改代码
   - 完成后，使用 `/commit` 命令提交代码

3. **退出并回到主仓库**
   - 输入 `exit` 命令
   - 选择 **保留 worktree**

4. **合并分支**
   - 切回主仓库目录
   - 手动执行 `git merge worktree-feature-auth` 进行合并
   - 或者告诉主仓库的 Claude "请合并分支"，让它帮你执行

5. **清理 worktree**
   ```bash
   git worktree remove .claude/worktrees/feature-auth
   git branch -d worktree-feature-auth
   ```

### 退出时的操作

当你在 worktree 中使用 `exit` 命令退出时，Claude Code 会提示你选择：

- **保留 worktree**：保留目录和分支，退出后你需要手动合并和清理
- **删除 worktree**：自动清理 worktree 目录和对应的分支（代码已提交的情况下）

注意：退出后不会自动合并，需要你切回主仓库手动合并或让 Claude 帮忙合并。

---

## 方法二：手动使用 git worktree（底层方法）

如果你需要更精细的控制，可以直接使用 git worktree 命令。**`claude --worktree` 底层就是使用 git worktree 实现的。**

### 初始化主仓库

首先，正常克隆你的项目作为"大本营"：

```bash
git clone <url> project-main
cd project-main
```

### 创建独立的工作树

使用 `git worktree add` 为不同任务创建独立的物理路径。建议统一放在 `.claude/worktrees/` 目录下：

```bash
# 任务 A：Bug 修复
git worktree add .claude/worktrees/bugfix -b fix/issue-1

# 任务 B：新功能
git worktree add .claude/worktrees/feature -b feat/new-api
```

### 多开 Claude 环境

打开多个终端窗口，分别进入对应的目录并启动 Claude：

| 终端窗口 | 路径                         | 任务                     |
| -------- | ---------------------------- | ------------------------ |
| 窗口 1   | `project-main/`              | 监控主分支，进行全局协调 |
| 窗口 2   | `.claude/worktrees/bugfix/`  | 专注修 Bug               |
| 窗口 3   | `.claude/worktrees/feature/` | 专注开发新功能           |

### 独立提交与合并

在各自的 Worktree 目录中完成代码修改并执行 `git commit`。完成后回到主仓库目录进行合并：

```bash
cd /path/to/project-main
git merge fix/issue-1
git merge feat/new-api
```

### 清理现场

任务完成后，按照"先删工作树，再删分支"的顺序清理：

```bash
# 移除工作树
git worktree remove .claude/worktrees/bugfix
git worktree remove .claude/worktrees/feature

# 删除已合并的本地分支
git branch -d fix/issue-1
git branch -d feat/new-api
```

---

## 工作原理

**Git worktree 是底层技术。** `claude --worktree` 命令本质上只是封装了 git worktree 的操作。

Git worktree 并不会复制整个仓库。它只是创建新的工作目录，并共享同一个 `.git` 对象库，因此：

- 占用空间非常小
- 创建速度非常快
- 非常适合 **AI Agent / Claude Code 并行开发**

### 核心优势

- **零摩擦切换**：你可以一边让 Claude 跑耗时较长的"全栈重构"，一边在另一个窗口秒开 Bug 修复，互不干扰。
- **上下文纯净**：每个 Worktree 下的 Claude 只关注当前分支的文件状态，不会被你在另一个分支写的临时代码误导。
- **环境隔离**：如果你的项目需要编译，不同的 Worktree 可以拥有独立的构建产物，避免频繁重新编译。
