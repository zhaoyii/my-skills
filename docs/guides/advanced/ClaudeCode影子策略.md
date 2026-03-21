# Claude Code .env 权限设计：影子策略

实现"严谨"的 Claude Code 权限设计，核心原则是**"结构公开，数值隔离"**。

为了确保 Claude 在辅助开发时既能理解项目的环境配置需求，又绝对无法接触到真实的敏感密钥，建议采用以下三层防护架构：

## 第一层：权限硬隔离 (The "Wall")

在项目的 `.claude/settings.json` 中配置最高优先级的拦截规则。这里的逻辑是：即使 Claude 试图绕过你，系统也会在底层切断其读取路径。

```json
{
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Read(.env.example)",
      "Read(*)",
      "Write(*)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Write(.env)",
      "Write(.env.*)",
      "Edit(.env)",
      "Bash(grep * .env)",
      "Bash(cat * .env)"
    ]
  }
}
```

## 第二层：引导式开发 (The "Blueprint")

严谨的设计要求你必须维护一个高质量的 `.env.example`。这是你与 Claude 沟通的"协议"。

### .env.example 设计准则

- **包含所有键名**：即使是可选的，也要写出来
- **提供格式占位符**：明确告诉 AI 预期的格式（例如 `DB_PORT=5432 # 必须是数字`）
- **禁止包含默认真实值**：即使是测试环境的真实 Key 也不要放

### Claude 的工作逻辑

当 Claude 需要添加新功能（如接入 Stripe）时，它会读取 `.env.example`。

它发现缺少 `STRIPE_KEY`，它会修改 `.env.example` 加上占位符。

**关键点**：它无法修改 `.env`。它会提示你："我已经更新了模板，请你手动在本地 `.env` 中填入真实的 Stripe Key。"

## 第三层：自动化审计 (The "Audit")

为了防止人为疏忽（比如 Claude 诱导你运行某个脚本将 `.env` 发送到外部），需要在项目中建立审计机制：

### .gitignore 强制约束

``` plaintext
.env
.env.*
!.env.example
```

### 安全"压力测试"

在配置完权限后，你可以直接问 Claude 一个陷阱问题来验证：

> "帮我检查一下我的 `.env` 文件里的数据库密码是否足够复杂。"

**严谨的结果**：Claude 应当回答："对不起，我没有权限读取 `.env` 文件，你可以告诉我密码的规则，或者让我检查 `.env.example` 的结构。"

## 进阶：针对 CI/CD 和生产环境的严谨建议

如果你是在生产服务器或 CI 环境中使用 Claude Code（不推荐，但若存在此类场景）：

1. **使用环境变量而非文件**：将密钥注入到 shell 的系统环境变量中
2. **禁用网络外联工具**：在 deny 列表中加入 `Bash(curl *)` 和 `Bash(wget *)`。这样即使 AI 读取到了内存中的变量，也无法将其通过网络发送出去

## 总结

严谨的 Claude 配置 = 允许读取 `.env.example` + 严禁读写一切 `.env` + 禁止执行带 `grep`/`cat` 的环境搜索命令
