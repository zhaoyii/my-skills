# Claude Code 内置命令分类与权限控制模型

## 1. 概述

Claude Code 的工具（Tools / Commands）本质是一组可被 AI Agent 调用的操作原语（Primitives）。
这些原语具有不同的副作用等级，需要通过 `permissions` 做精细化控制。

---

## 2. 核心命令分类模型

建议采用统一的五类抽象：

READ      → 读取信息（无副作用）  
WRITE     → 创建资源（新增）  
EDIT      → 修改资源（变更）  
EXECUTE   → 执行命令（强副作用）  
META      → 元操作（辅助推理）  

---

## 3. 一、完整权限执行流程（核心）

当 Claude 尝试执行一个 Tool（比如 Edit / Bash），会按这个顺序决策：

1. Hooks（前置拦截）
2. Deny 规则
3. Allow 规则
4. Ask 规则
5. Permission Mode
6. 运行时审批（canUseTool / 用户确认）
7. 执行 Tool
8. Hooks（后置）

### 官方依据

该执行顺序来自 Claude Code 官方文档中的权限机制说明（Permissions / Agent 执行流程）。

核心结论：

- Deny 永远优先级最高（硬阻断）
- Allow 控制自动执行
- Ask 触发 Human-in-the-loop
- Mode 是全局兜底策略
- Hooks 可在执行前后拦截和扩展行为

### 权限设计最佳实践（非常关键）

设计权限时建议严格遵循以下顺序：

```text
先设计 Deny → 再设计 Allow → 最后设计 Ask
```

并且在 `settings.json` 中也按这个顺序组织：

```json
{
  "permissions": {
    "deny": [...],
    "allow": [...],
    "ask": [...]
  }
}
```

#### 原因

1. **安全优先（Security First）**
   - Deny 定义绝对边界（如 secrets / rm / 网络操作）

2. **最小权限原则（Least Privilege）**
   - Allow 只开放必要能力

3. **人机协同（Human-in-the-loop）**
   - Ask 作为兜底审批层

👉 本质：

> Deny = 安全底线  
> Allow = 自动化能力  
> Ask = 风险缓冲层  

---

## 4. 命令分类详解

### 4.1 READ（读取）

定义：只读操作，不修改任何状态

典型命令：
- Read(file)
- Glob(pattern)
- Grep(pattern)
- LS(dir)

特性：
- 幂等（idempotent）
- 无副作用
- 可重复执行

风险：
- 敏感信息泄漏（如 `.env`、密钥文件）

建议：
```json
{
  "deny": ["Read(.env*)", "Read(secrets/**)"]
}
```

---

### 4.2 WRITE（创建）

定义：创建新资源，不修改已有资源

典型命令：
- Write(file)
- Create(file)

特性：
- 仅新增
- 不覆盖已有内容

风险：
- 写入恶意文件
- 污染代码仓库

---

### 4.3 EDIT（修改）

定义：对已有资源进行修改（最关键能力）

典型命令：
- Edit(file)
- MultiEdit(file)

特性：
- 基于 diff 修改
- 可控但有副作用

风险：
- 修改错误逻辑
- 引入 bug
- 删除关键代码

建议：
- 必须配合 hook 做校验（lint / test）

---

### 4.4 EXECUTE（执行）

定义：执行系统命令（最高风险）

典型命令：
- Bash(command)

特性：
- 强副作用
- 非确定性
- 可访问系统与网络

风险等级：
- 最高（High Risk）

建议：
- 严格白名单控制
- 禁止危险命令

---

### 4.5 META（元操作）

定义：辅助 AI 推理与任务管理

典型命令：
- Task
- Plan
- Search

特性：
- 无直接副作用
- 影响 AI 决策路径

---

## 5. 标准安全配置模板

```json
{
  "permissions": {
    "deny": [
      "Read(.env*)",
      "Bash(rm:*)",
      "Bash(curl:*)"
    ],
    "allow": [
      "Read(*)",
      "LS(*)",
      "Glob(*)"
    ],
    "ask": [
      "Edit(*)",
      "Write(*)",
      "Bash(git:*)"
    ]
  }
}
```

---

## 6. 总结

Claude Code 权限系统本质是：

**Hook + ACL + Mode + Runtime Approval 的组合决策流水线**

设计原则：

- 安全优先
- 最小权限
- 可审计
- 可控自动化
