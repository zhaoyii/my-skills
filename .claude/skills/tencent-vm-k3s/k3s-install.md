---
date: 2026-04-08
description: 基于 Master 节点"完整安装"经验，整理的标准化的腾讯云 k3s 集群部署流程 (1 Master + 3 Worker)
---

## 腾讯云 k3s 高可用集群部署文档 (1 Master + 3 Worker)

---

### 1. 部署环境与前提条件

| 项目 | 说明 |
|------|------|
| 操作系统 | TencentOS Server 4 (基于 RHEL 9) |
| 服务器配置 | 4 台腾讯云 CVM/轻量服务器 |
| 网络 | 所有服务器处于同一 VPC（私有网络）下 |
| 权限 | 具备 root 或 sudo 权限 |

**机器角色规划**

| 主机名 | 内网 IP (示例) | 角色 | 核心任务 |
|--------|---------------|------|----------|
| master-01 | 10.0.0.5 | Master (Control Plane) | 管理节点、API Server、调度 |
| worker-01 | 10.0.0.6 | Agent (Worker) | 运行业务容器 |
| worker-02 | 10.0.0.7 | Agent (Worker) | 运行业务容器 |
| worker-03 | 10.0.0.8 | Agent (Worker) | 运行业务容器 |

---

### 2. 网络安全组配置建议

为了确保集群通信正常且公网安全，建议将 4 台机器关联至同一个安全组。

**出站规则 (Outbound)**

核心建议：**全放通**

| 规则 | 说明 |
|------|------|
| 协议 ALL, 目标 0.0.0.0/0, 策略 允许 | 确保服务器能正常访问腾讯云镜像源、同步 NTP 时间以及下载 K3s 核心二进制文件 |

**入站规则 (Inbound)**

| 协议 | 端口 | 来源 | 策略 | 说明 |
|------|------|------|------|------|
| ALL | - | 当前安全组 ID | 允许 | 让同一安全组内的 4 台机器之间可以自由通信，不受端口限制，确保 K3s 集群内部网络流量（如 6443 API Server、8472 VXLAN 等）正常工作 |
| TCP | 6443 | 你的办公/家庭固定 IP | 允许 | 允许远程通过 kubectl 管理集群 |
| TCP | 80/443 | 0.0.0.0/0 | 允许 | 允许公网访问你部署的 Web 业务 |
| TCP | 22 | 你的管理 IP | 允许 | SSH 远程登录 |

---

### 3. 基础环境准备 (所有节点执行)

由于 TencentOS 4 的 SELinux 依赖较新，需手动补齐仓库以实现"完整安装"。

```bash
# 1. 配置 CentOS Stream 9 AppStream 兼容源（解决 container-selinux 依赖）
cat <<EOF | sudo tee /etc/yum.repos.d/centos-stream-appstream.repo
[centos-stream-appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/
gpgcheck=0
enabled=1
EOF

# 2. 安装核心依赖
sudo yum clean all && sudo yum makecache
sudo yum install -y container-selinux

# 3. 关闭系统自带防火墙（可选，若存在；避免与 K8s 转发规则冲突）
sudo systemctl disable firewalld --now
```

---

### 4. 集群部署

#### 4.1 部署 Master 节点

在 master-01 上执行，跳过 selinux rpm 安装（`rpm.rancher.io` 国内部分网络不通）：

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  INSTALL_K3S_MIRROR=cn \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  sh -s - \
  --write-kubeconfig-mode 644 \
  --node-name master-01
```

记录 Token (在 Master 执行):

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
# 记录输出的 Token 字符串，后续 Slave 加入需使用
```

#### 4.2 部署 Worker (Slave) 节点

在 3 台 worker 机器上分别执行（替换 IP 和 Token）：

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  INSTALL_K3S_MIRROR=cn \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  K3S_URL=https://<MASTER_内网_IP>:6443 \
  K3S_TOKEN=<MASTER_TOKEN> \
  sh -s - \
  --node-name worker-01  # 对应修改为 01, 02, 03
```

#### 4.3 补装 k3s-selinux（所有节点执行）

**报错原因**

不跳过时会遇到如下错误：

```
[WARN]  Failed to get available versions of k3s-selinux..defaulting to k3s-selinux-1.2-2.el9.noarch.rpm
Error: Failed to download metadata for repo 'rancher-k3s-common-stable': Cannot download repomd.xml
```

原因：`INSTALL_K3S_MIRROR=cn` 只影响 k3s 二进制下载，selinux rpm 走 `rpm.rancher.io`（国内部分网络超时），且脚本默认 fallback 到旧版本 `1.2-2`（已下架）。

**解决方案**：跳过安装后，从 GitHub 手动下载上传安装。

```bash
# 1. 在能联网的机器上下载（最新版本 v1.6.latest.1）
# TencentOS 4 基于 RHEL 9，选 el9 版本
wget https://github.com/k3s-io/k3s-selinux/releases/download/v1.6.latest.1/k3s-selinux-1.6-1.el9.noarch.rpm -O /tmp/k3s-selinux.rpm

# 2. 传到所有节点（Master 和 Worker）
scp /tmp/k3s-selinux.rpm root@master-01:/tmp/
scp /tmp/k3s-selinux.rpm root@worker-01:/tmp/
scp /tmp/k3s-selinux.rpm root@worker-02:/tmp/
scp /tmp/k3s-selinux.rpm root@worker-03:/tmp/

# 3. 所有节点执行安装
sudo rpm -ivh /tmp/k3s-selinux.rpm
```

**常见问题**

| 问题 | 原因 | 处理 |
|------|------|------|
| `Failed to connect to github.com` | GitHub 被墙 / 网络不可达 | 从其他节点中转、找代理、或使用镜像站 |
| `Connection timed out` | 防火墙阻断 / DNS 污染 | 更换网络或使用国内代理 |
| `wget: command not found` | 系统未安装 wget | `sudo yum install -y wget` |
| `403 Forbidden` | 直接下载需科学上网 | 使用代理或中转下载 |

---

### 5. 验证与后期配置

#### 节点验证

在 Master 节点执行：

```bash
# 检查所有节点状态
kubectl get nodes

# 预期输出：
# master-01   Ready    control-plane,master   ...
# worker-01   Ready    <none>                 ...
# worker-02   Ready    <none>                 ...
# worker-03   Ready    <none>                 ...
```

#### 混合部署标签 (可选)

为了后续实现开发/测试/生产的隔离，建议给节点打标：

```bash
kubectl label node worker-01 env=prod
kubectl label node worker-02 env=test
kubectl label node worker-03 env=dev
```

#### 镜像加速优化

为了加快 Pod 启动速度，建议修改**所有节点**的 `/etc/rancher/k3s/registries.yaml` 使用腾讯云内网加速：

```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://mirror.ccs.tencentyun.com"
```

修改后执行：
- Master 节点执行 `sudo systemctl restart k3s`
- Worker 节点执行 `sudo systemctl restart k3s-agent`

---

> **文档说明**: 该方案通过手动补齐 container-selinux 依赖，实现了 k3s 的全功能部署，能够充分利用 TencentOS 的安全特性。
>
> **安装问题与处理方式**: `INSTALL_K3S_MIRROR=cn` 只影响 k3s 二进制下载，selinux rpm 走 `rpm.rancher.io`（国内部分网络超时），且 fallback 到已下架旧版本导致失败。使用 `INSTALL_K3S_SKIP_SELINUX_RPM=true` 跳过安装，改为从 GitHub 下载最新版本手动安装。
