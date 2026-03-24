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

## 3. 命令分类详解

### 3.1 READ（读取）

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

### 3.2 WRITE（创建）

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

### 3.3 EDIT（修改）

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

### 3.4 EXECUTE（执行）

定义：执行系统命令（最高风险）

典型命令：
- Bash(command)

示例：
- rm -rf /
- npm publish
- docker push

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

### 3.5 META（元操作）

定义：辅助 AI 推理与任务管理

典型命令：
- Task
- Plan
- Search

特性：
- 无直接副作用
- 影响 AI 决策路径

---

## 4. 权限系统映射

Claude 使用以下结构控制权限：

```json
{
  "allow": [],
  "ask": [],
  "deny": []
}
```

含义：
- allow：允许自动执行
- ask：执行前需确认
- deny：禁止执行

---

## 5. 推荐权限分级模型

### Level 1（安全）
```json
{
  "allow": ["Read(*)", "LS(*)", "Glob(*)"]
}
```

---

### Level 2（可控修改）
```json
{
  "ask": ["Edit(*)", "Write(*)"]
}
```

---

### Level 3（高风险）
```json
{
  "ask": ["Bash(*)"]
}
```

或更严格：

```json
{
  "deny": ["Bash(rm:*)", "Bash(curl:*)"]
}
```

---

## 6. 粒度控制示例

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)"
    ],
    "ask": [
      "Bash(git commit:*)"
    ],
    "deny": [
      "Bash(git push:*)"
    ]
  }
}
```

---

## 7. 工程最佳实践

### 7.1 按副作用强度设计权限

READ < WRITE < EDIT < EXECUTE

---

### 7.2 EDIT 必须配合 Hook

```json
{
  "hooks": {
    "PostToolUse": {
      "Edit": "npm run lint"
    }
  }
}
```

---

### 7.3 EXECUTE 必须白名单

推荐：
```json
"Bash(git:*)"
```

避免：
```json
"Bash(*)"
```

---

### 7.4 READ 必须防泄漏

```json
{
  "deny": [
    "Read(.env*)",
    "Read(secrets/**)"
  ]
}
```

---

## 8. 标准安全配置模板

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "LS(*)",
      "Glob(*)"
    ],
    "ask": [
      "Edit(*)",
      "Write(*)",
      "Bash(git:*)"
    ],
    "deny": [
      "Read(.env*)",
      "Bash(rm:*)",
      "Bash(curl:*)"
    ]
  }
}
```

---

## 9. 总结

Claude Code 命令体系本质：

一组带副作用等级的操作原语（effectful primitives）

权限系统本质：

对这些原语的访问控制（ACL）

核心设计原则：

- 最小权限
- 强隔离
- 可审计
- 可回滚
