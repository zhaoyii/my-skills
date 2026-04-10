---
name: claude-ssh-remote
description: claude code 通过 SSH 管理远程服务器的完整配置流程
keywords:
  - claude code
  - ssh
  - key-based auth
  - 免密登录
tags:
  - 配置指南
  - SSH
created: 2026-04-10
updated: 2026-04-10
---

# Claude Code SSH 远程服务器管理

通过 SSH 远程管理服务器，私钥文件为 `your-key-id_ed25519`。

## 1. 规范文件权限

SSH 对密钥权限极其敏感，权限过大会导致连接被拒绝（WSL 环境）。

```bash
chmod 600 ~/.ssh/your-key-id_ed25519
chmod 644 ~/.ssh/your-key-id_ed25519.pub
```

## 2. 写入 SSH Config 配置文件

编辑 `~/.ssh/config`，通过别名绑定密钥。

```bash
nano ~/.ssh/config
```

配置内容：

```plaintext
Host iot-server
    HostName 192.168.1.100
    User root
    IdentityFile ~/.ssh/your-key-id_ed25519
    IdentitiesOnly yes
```

## 3. 将公钥同步至远程服务器

指定对应的公钥文件进行上传（**需输入最后一次 root 密码**）。

```bash
ssh-copy-id -i ~/.ssh/your-key-id_ed25519.pub iot-server
```

## 4. 免密验证

```bash
ssh iot-server
```

如果能直接进入服务器命令行，说明配置成功。

## 5. Claude Code 实战命令

在本地 Claude 窗口中，使用别名指挥远程服务器操作。

**巡检** - 查看磁盘和内存使用情况
```bash
ssh iot-server 'df -h && free -h'
```

**部署** - 复制文件到远程并重启服务
```bash
scp ./app iot-server:/opt/app/ && ssh iot-server 'systemctl restart app'
```

**监控** - 实时查看错误日志
```bash
ssh iot-server 'tail -f /var/log/syslog | grep ERROR'
```

## 设计原则

| 原则 | 说明 |
|------|------|
| 简洁性 | Claude 只需识别 `iot-server` 别名，无需知道私钥路径和 IP |
| 安全性 | `IdentitiesOnly yes` 确保只使用指定密钥，避免触发防火墙拦截 |
| 原子化 | 新增服务器只需在 Config 中增加 Host 段落，互不干扰 |