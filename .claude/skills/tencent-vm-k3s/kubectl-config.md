---
date: 2026-04-08
description: 腾讯云 k3s 集群 kubectl 配置指南
---

## kubectl 配置指南

### 前置条件

**1. 查询本机公网 IP**

```bash
curl ifconfig.me
```

**2. 配置安全组入站规则**

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 6443 | 你的公网 IP（107.152.46.174/32） | kubectl 远程管理 |

---

### 1. 获取 kubeconfig

K3s 安装时已通过 `--write-kubeconfig-mode 644` 生成了配置文件：

```bash
# 在 master-01 上查看
cat /etc/rancher/k3s/k3s.yaml
```

### 2. 本地访问集群

#### 方式一：直接复制 kubeconfig（单集群推荐）

```bash
# 1. 从 master 复制到本地
scp root@<MASTER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# 2. 修改 server 地址为公网 IP
sed -i 's|https://127.0.0.1:6443|https://<MASTER公网IP>:6443|g' ~/.kube/config

# 3. 验证
kubectl get nodes
```

#### 方式二：多集群上下文

在同一台机器管理多个集群时使用：

```bash
# 1. 添加集群
kubectl config set-cluster k3s-prod \
  --server=https://<MASTER公网IP>:6443 \
  --kubeconfig=~/.kube/config

# 2. 添加凭证（跳过证书验证，仅测试）
kubectl config set-credentials k3s-admin \
  --kubeconfig=~/.kube/config

# 3. 创建上下文
kubectl config set-context k3s-prod-admin \
  --cluster=k3s-prod \
  --user=k3s-admin \
  --kubeconfig=~/.kube/config

# 4. 使用该上下文
kubectl config use-context k3s-prod-admin
```

#### 常用上下文命令

```bash
kubectl config get-contexts          # 查看所有上下文
kubectl config current-context       # 查看当前上下文
kubectl config use-context <name>    # 切换上下文
```

### 3. 测试验证

按顺序执行以下命令，逐步验证连接：

```bash
# 1. 检查集群节点状态
kubectl get nodes -o wide

# 2. 检查 API Server 版本
kubectl version --short

# 3. 检查所有命名空间
kubectl get ns

# 4. 检查系统 Pod 运行状态
kubectl get pods -A

# 5. 检查集群信息
kubectl cluster-info
```

**预期输出示例：**

```
# kubectl get nodes -o wide
NAME        STATUS   ROLES                       AGE   VERSION    INTERNAL-IP
master-01   Ready    control-plane,master       24h   v1.28.4    10.0.0.5
worker-01   Ready    <none>                     24h   v1.28.4    10.0.0.6
worker-02   Ready    <none>                     24h   v1.28.4    10.0.0.7
worker-03   Ready    <none>                     24h   v1.28.4    10.0.0.8

# kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS
kube-system   coredns-59b4f5bbd5-xk9gh                 1/1     Running
kube-system   local-path-provisioner-7b7dc8d6f5-h4l2m  1/1     Running
kube-system   metrics-server-648d8b7b64-2b9fq          1/1     Running
```

### 4. 证书 SANs 配置（公网访问必需）

K3s 证书默认只包含内网 IP，直接用公网 IP 访问会报证书错误：

```
x509: certificate is valid for 10.0.0.5, 10.43.0.1, 127.0.0.1, ::1, not 43.139.62.59
```

**解决方法：在 master 节点执行**

```bash
# 1. 查看 k3s 二进制路径
which k3s

# 2. 停止 k3s
sudo systemctl stop k3s

# 3. 修改 service 文件，添加公网 IP 到 SANs
sudo vim /etc/systemd/system/k3s.service
# 在 ExecStart 行尾添加：--tls-san 你的公网IP
# 例如：ExecStart=/usr/local/bin/k3s server --tls-san 43.139.62.59

# 4. 重载并重启
sudo systemctl daemon-reload
sudo systemctl restart k3s

# 5. 确认 k3s 运行正常
sudo systemctl status k3s
```

**永久生效方式**：安装时直接指定：

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  INSTALL_K3S_MIRROR=cn \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  sh -s - \
  --write-kubeconfig-mode 644 \
  --node-name master-01 \
  --tls-san 43.139.62.59      # 添加公网 IP
```

### 5. 常见问题

| 问题 | 解决 |
|------|------|
| `Unable to connect to the server` | 检查安全组是否开放 6443 端口 |
| `x509: certificate is valid for ... not` | 证书 SANs 不包含公网 IP，见上文"证书 SANs 配置" |
| `no context` | 检查 kubeconfig 是否正确加载 |