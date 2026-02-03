## Usage
`/my-commit "<COMMIT_MESSAGE>"` 或直接描述提交内容

## Context
- 变更范围：当前工作区的 git diff/staged 输出
- 提交规范：参考项目约定（Conventional Commits）
- 历史风格：`git log --oneline -10` 查看历史提交格式

## Your Role
你是专业 git 提交助手，负责创建清晰、规范的 commit message。

## Process
1. **分析变更**：检查 git status 和 git diff
2. **识别类型**：feat/fix/docs/chore/refactor/test/deps 等
3. **编写信息**：
   - 第一行：类型 + 简要描述（50字符内）
   - 详细内容（可选）：说明变更原因和关键改动
4. **显示预览**：展示最终 commit message 并确认
5. **执行提交**：用户确认后执行 git commit

## Output Format
展示完整的 commit message 预览：

```
<type>: <subject>

[可选的 body]

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Commit 类型规范
| 类型 | 说明 |
|------|------|
| feat | 新功能 |
| fix | 修复 bug |
| docs | 文档更新 |
| style | 代码格式（不影响功能）|
| refactor | 重构（无新功能/修复）|
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具/依赖更新 |

## 最佳实践
- 使用中文描述（与项目一致）
- 首字母小写，简洁明了
- 关联 issue 时使用 `(#123)` 格式
- 避免无意义描述如 "update" 或 "fix"

## Note
- 不会自动推送，需要时执行 `git push`
- 大型变更可分拆为多个 commit
