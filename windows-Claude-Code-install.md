# Windows Claude Code + VSCode 安装指南

## 前置依赖

| 依赖项 | 安装方式 |
|--------|----------|
| ripgrep | 执行命令`winget install BurntSushi.ripgrep.MSVC` |
| Node.js | [官网下载](https://nodejs.org/en/download) |
| Git | [官网下载](https://git-scm.com/install/windows) |

## 安装步骤

### 1. 设置执行策略（临时放行）

此方式最安全：
- 只对当前 PowerShell 会话生效
- 窗口关闭后自动失效
- 不修改系统级策略

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 2. 执行安装脚本

```powershell
irm https://claude.ai/install.ps1 | iex
```

> 提示：这是官方推荐的安装方式。

## 验证安装

打开新的 PowerShell 终端，运行：

```powershell
claude --version
```

成功安装后应显示版本号。首次运行会自动打开浏览器进行登录认证。
