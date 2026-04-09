# k3s + 腾讯云 CLB 自动化集成方案 (2026版)

## 1. 架构原理

该方案通过腾讯云官方的云控制器（CCM）接管 Traefik 的 Service。

- **自动感知**：当新节点加入或离开 k3s 集群时，CCM 自动调用腾讯云 API 修改 CLB 的后端绑定列表
- **证书卸载**：HTTPS 在 CLB 层终止，集群内部走 HTTP，简化证书管理
- **源 IP 保留**：直接透传客户端真实 IP 到 Traefik

## 2. 第一步：安装腾讯云 CCM 插件

在 k3s 集群中部署 CCM，赋予其操作 CLB 的权限。

### 2.1 创建权限凭证

在所有 Master 节点上执行，替换为你的腾讯云 API 密钥：

```bash
cat <<EOF > /etc/kubernetes/cloud-config
{
    "global": {
        "secretId": "YOUR_SECRET_ID",
        "secretKey": "YOUR_SECRET_KEY",
        "region": "ap-guangzhou"
    }
}
EOF
```

### 2.2 API 密钥作用

腾讯云 API 密钥在方案中的核心作用：

- **身份认证**：CCM 通过 `secretId` + `secretKey` 认证来调用腾讯云 API
- **权限控制**：密钥关联的 CAM 角色/策略需包含：
  - `cvm:DescribeInstances` — 查询云服务器实例列表
  - `clb:*` — 操作负载均衡（创建、绑定、解绑后端节点等）
- **工作流程**：CCM 监听集群 Node 增减事件 -> 调用腾讯云 API -> 自动修改 CLB 后端绑定

> 建议使用子账号密钥，并为子账号绑定最小权限策略，避免主账号密钥泄露风险。

### 2.3 配置 k3s 启动参数

在所有 Master 节点上编辑 k3s 服务配置：

```bash
sudo vi /etc/systemd/system/k3s.service
```

在 `[Service]` 段添加环境变量：

```ini
Environment="K3S_KUBELET_ARGS=--cloud-provider=external"
Environment="K3S_CONTROLLER_MANAGER_ARGS=--cloud-provider=external --cloud-config=/etc/kubernetes/cloud-config"
```

重启使配置生效：

```bash
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

### 2.4 部署 CCM（YAML 方式）

下载并部署腾讯云官方 [YAML](manifests/cloud-controller-manager.yaml)：

```bash
curl -fsSL -o cloud-controller-manager.yaml https://raw.githubusercontent.com/TencentCloud/tencentcloud-cloud-controller-manager/master/docs/example-manifests/out-of-tree/cloud-controller-manager.yaml

kubectl apply -f cloud-controller-manager.yaml
```

> CCM 只需部署在 Master 节点，默认即有高可用。

## 3. 第二步：配置 Traefik 持久化 (自动化核心)

编辑 k3s 的 Helm 配置文件，使 Traefik 自动关联 CLB：

```bash
sudo vi /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
```

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    service:
      type: LoadBalancer
      annotations:
        # 指定使用已有 CLB 实例（推荐先手动创建一个空 CLB）
        service.cloud.tencent.com/exist-lb-id: "lb-xxxxxxxx"

        # 核心：开启自动同步后端节点
        service.cloud.tencent.com/local-backend-endpoints: "true"

        # 负载均衡协议配置
        service.cloud.tencent.com/direct-access: "true"

      spec:
        # 保留真实源 IP
        externalTrafficPolicy: Local
```

## 4. 第三步：CLB 监听器设置

在腾讯云控制台对指定的 `lb-xxxxxxxx` 进行如下设置：

### 4.1 端口映射

- **80 监听器**：监听协议 HTTP，后端端口映射到集群自动分配的 NodePort（或直接映射 80）
- **443 监听器**：监听协议 HTTPS，绑定 SSL 证书，后端协议选择 HTTP，后端端口同上

### 4.2 健康检查

检查端口：使用 Traefik 的健康检查端口（默认通常是业务端口或 8080）。

### 4.3 自动感应测试

当新增一个 k3s Agent 节点并加入集群后，几秒钟内你会在 CLB 的"后端服务器"列表中看到该节点的内网 IP 自动出现。

## 5. 第四步：部署业务 Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  annotations:
    # 强制所有请求跳转到 HTTPS
    traefik.ingress.kubernetes.io/router.middlewares: kube-system-redirect-https@kubernetescrd
spec:
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## 6. 关键运维要点

### 6.1 安全组闭环

为防止外部绕过 CLB 直接访问节点，安全组应配置为：

- **节点安全组**：仅允许来自 CLB 所在安全组的流量访问 NodePort 范围
- **CLB 安全组**：允许公网（0.0.0.0/0）访问 80/443

### 6.2 节点变动观察

- **扩容**：k3s agent 加入集群 -> CCM 监测到新 Node -> 调用 API -> CLB 后端增加 IP
- **缩容**：节点停机 -> K8s 标记 Node NotReady -> CCM 监测到变更 -> CLB 后端自动剔除 IP

### 6.3 常见问题排除

如果 CLB 后端没有自动同步，请检查 Master 节点的日志：

```bash
kubectl logs -n kube-system -l app=tencentcloud-cloud-controller-manager
```

确认 API 密钥是否有 `cvm:DescribeInstances` 和 `clb:*` 的相关权限。

## 总结

这套方案实现了"一劳永逸"，你只需要管理 k3s 节点的增减，公网接入层会自动随之伸缩。
