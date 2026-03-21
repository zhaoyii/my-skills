# Permissions 配置参考

## 核心参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `permissions.defaultMode` | `string` | 默认权限模式 |
| `permissions.allow` | `string[]` | 自动允许的规则 |
| `permissions.ask` | `string[]` | 始终询问的规则 |
| `permissions.deny` | `string[]` | 拒绝的规则 |

## defaultMode

| 值 | 行为 |
|---|------|
| `default` | 首次使用时询问 |
| `acceptEdits` | 自动接受文件编辑 |
| `plan` | 仅分析，不修改 |
| `dontAsk` | 自动拒绝（除非预批准） |
| `bypassPermissions` | 跳过提示（受保护目录除外） |

## 规则语法

### 工具匹配

```json
"Read"           // 所有读取
"Bash"           // 所有命令
"Edit"           // 所有编辑
"Write"          // 所有写入
"WebFetch"       // 所有网络请求
```

### 路径匹配

| 模式 | 含义 | 示例 |
|------|------|------|
| `//path` | 绝对路径（POSIX） | `Read(//c/**/.env)` |
| `~/path` | home 目录 | `Read(~/.npmrc)` |
| `/path` | 项目根目录相对 | `Read(/src/**)` |
| `path` | 当前目录相对 | `Read(*.md)` |

- `*` 匹配单层目录
- `**` 匹配递归目录

### 命令匹配

```json
"Bash(npm run build)"    // 精确匹配
"Bash(npm run *)"        // 前缀匹配
"Bash(* install)"        // 后缀匹配
"Bash(git * main)"      // 中间匹配
```

## 示例配置

```json
{
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Read(config/schema/**)",
      "Read(config/example/**)",
      "Read(src/**)",
      "Edit(src/**)",
      "Write(src/**)",
      "Bash(git status *)",
      "Bash(git commit *)",
      "Bash(pnpm run dev)"
    ],
    "ask": [
      "Bash(git push *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env*)",
      "Read(*secret*)",
      "Read(*password*)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(rm -rf *)",
      "Bash(cat *.env*)",
      "Bash(printenv*)"
    ]
  }
}
```

## 优先级

`deny` > `ask` > `allow`

第一个匹配的规则生效。
