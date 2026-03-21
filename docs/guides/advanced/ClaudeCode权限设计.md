# Claude Code 权限设计原则

## 一、核心问题

Claude Code 的权限设计本质是在解决：

> **如何让 AI 高效参与开发，同时避免读取敏感信息和执行危险操作**

主要风险：

1. 敏感信息泄露（.env / config / secrets）
2. 命令执行风险（curl / rm -rf）
3. Bash 绕过读取
4. 过度授权

---

## 二、设计原则

### 最小权限原则

只开放必要能力，避免 `Bash(*)`。

### 配置与密钥分离

- `config` = 结构
- `secrets` = 值

### 分层隔离

- `example/schema` → 可读
- `dev` → 可读（脱敏）
- `prod/secrets` → 禁止

### 防止 Bash 绕过

不仅限制 Read，还要限制 Bash。

---

## 三、目录结构

```
config/
├── schema/
├── example/
├── dev/
├── prod/
└── secrets/
```

---

## 四、defaultMode

| 模式 | 行为 | 适用场景 |
|------|------|----------|
| `default` | 未匹配时询问 | 推荐 |
| `dontAsk` | 自动执行 | CI 环境 |
| `plan` | 仅规划 | 预览模式 |
| `bypassPermissions` | 全开放 | **禁止** |

---

## 五、权限模板

```json
{
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Read(config/schema/**)",
      "Read(config/example/**)",
      "Read(config/dev/**)",
      "Read(src/**)",
      "Write(src/**)",
      "Edit(src/**)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(pnpm run dev)"
    ],
    "ask": [
      "Bash(git push *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(config/prod/**)",
      "Read(config/secrets/**)",
      "Bash(cat *.env*)",
      "Bash(printenv*)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(rm -rf *)",
      "Bash(git reset *)"
    ]
  }
}
```

---

## 六、关键点

- **允许**：结构 + 示例 + 开发配置
- **禁止**：真实配置 + secrets + 网络 + 危险命令

---

## 七、一句话总结

Claude 只接触结构，不接触密钥。
