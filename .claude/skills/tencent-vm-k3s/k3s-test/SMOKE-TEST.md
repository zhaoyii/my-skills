---
title: K3s Ingress 链路验证
description: 最小可验证（smoke test）的 Ingress + Service + Deployment 示例，在 K3s 中验证 Pod → Service → Ingress → 访问 完整链路。
tags:
  - k3s
  - ingress
  - smoke-test
---

# K3s Ingress 链路验证 (Smoke Test)

## 部署

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## 验证

### 1. 查看资源

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

### 2. 获取访问地址

```bash
# 获取 Ingress 外部访问地址
kubectl get ingress demo-nginx-ingress
```

远程环境可能已配置 DNS 或使用 LoadBalancer，访问地址由 Ingress Controller 分配。

### 3. 访问测试

#### 方式 A：NodePort 直连（内网测试，绕过备案）

```bash
# 在任意能访问 k3s 节点内网 IP 的机器上执行
curl -H "Host: www.luojialbs.com" http://<节点内网IP>:31080/
# 例如
curl -H "Host: www.luojialbs.com" http://172.16.24.9:31080/
```

#### 方式 B：CLB 公网（需域名已备案）

```bash
curl -H "Host: www.luojialbs.com" http://<CLB公网IP>/
# 例如
curl -H "Host: www.luojialbs.com" http://43.144.78.250/
```

看到 Nginx 页面说明链路打通。

## 排查

```bash
kubectl get ingress
kubectl describe ingress demo-nginx-ingress
kubectl get svc
kubectl get endpoints demo-nginx-service
kubectl get pods -o wide
```

确认项：

- Service selector 是否匹配 Pod label
- Pod 是否 Running
- Ingress host 是否匹配访问域名
- Traefik 是否运行

```bash
kubectl get pods -n kube-system | grep traefik
```

## 镜像配置

配置 K3s 使用腾讯云内网镜像加速拉取。

### 1. 配置镜像源

```bash
# 配置 registries.yaml
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml << 'EOF'
mirrors:
  docker.io:
    endpoint:
      - "https://mirror.ccs.tencentyun.com"
EOF
```

### 2. 重启 K3s

```bash
# 控制平面
sudo systemctl restart k3s

# 所有 worker 节点
sudo systemctl restart k3s-agent
```

### 3. 验证镜像源

```bash
# 测试镜像是否可用
curl -I https://mirror.ccs.tencentyun.com/v2/rancher/mirrored-pause/manifests/3.6
# 返回 200 表示可用
```

## 资源说明

| 资源 | 名称 | 说明 |
|------|------|------|
| Deployment | demo-nginx | 2 副本 Nginx |
| Service | demo-nginx-service | ClusterIP 类型，端口 80 |
| Ingress | demo-nginx-ingress | 域名 demo.local |
