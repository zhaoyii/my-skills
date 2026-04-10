---
description: 通过腾讯云控制台手动管理 CLB 后端服务器，不依赖 CCM 插件，架构纯粹，适合节点变动不频繁的生产环境。
---

# k3s + 腾讯云 CLB (NodePort 手动模式) 优化文档

## 1. 核心架构逻辑

- **k3s 集群**：运行 Traefik 作为 Ingress Controller
- **Service (NodePort)**：将 Traefik 的 80/443 端口固定映射到物理节点的端口（如 31080/31443）
- **腾讯云 CLB**：作为流量入口，手动绑定所有 Node 的内网 IP 和固定端口

```
流量拓扑：
CLB（80/443）→ NodeIP:NodePort（Traefik）→ Ingress（域名路由）→ Service → Pod
```

## 2. 前置条件：确认 Traefik 已部署

```bash
# 检查 Traefik 是否已部署并运行
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# 检查 Traefik Service 是否存在
kubectl get svc -n kube-system traefik
```

确保 Traefik Pod 状态为 `Running`，再进行下一步。

## 3. 步骤一：持久化配置 Traefik 为 NodePort

在 k3s 中，直接 `kubectl edit` 会在重启后失效。必须通过 HelmChartConfig 进行持久化。

在 Master 节点执行：

```bash
sudo vi /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
```

[参考配置如下](https://chat.deepseek.com/a/chat/s/c59f9c0e-8449-4a61-a23e-db75d4e9d450)
```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    deployment:
      enabled: true
      replicas: 2
      # 修正为软亲和，避免单节点无法调度
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: traefik
            topologyKey: kubernetes.io/hostname

    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "1000m"      # 适度提高 CPU 限制
        memory: "1Gi"     # 提高内存限制，防止配置多导致 OOM

    service:
      type: NodePort
      # 建议显式设置为 Cluster，依赖 CLB 七层转发获取 X-Forwarded-For
      # externalTrafficPolicy: Cluster 
    
    ports:
      web:
        nodePort: 31080
      websecure:
        nodePort: 31443

    # 开启 ping 并将路径挂在业务端口，方便 CLB 直接探测
    ping:
      enabled: true
      entryPoint: "web"   # 关键修改：让 /ping 通过 31080 访问

    # logs:
    #   general:
    #     level: INFO
    #   access:
    #     enabled: true
    #     # 确保访问日志中能看到真实 IP（需要配合 X-Forwarded-For）
    #     fields:
    #       headers:
    #         defaultmode: keep
    #         names:
    #           X-Forwarded-For: keep
```

执行后稍等片刻，Traefik 会自动重启并绑定这两个固定端口。

**验证方法**：

```bash
# 检查 Traefik Service 是否已暴露为 NodePort
kubectl get svc -n kube-system traefik -o wide

# 确认端口已固定为 31080/31443
kubectl get svc -n kube-system traefik -o jsonpath='{.spec.ports[*]}'

# 查看 Traefik Pod 是否正在运行
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

**常见问题**：

- `NotFound`：Traefik 未安装。k3s 默认会安装 Traefik，如未安装请检查 k3s 日志。
- Service 名称不是 `traefik`：检查实际名称：
  ```bash
  kubectl get svc -n kube-system | grep -i traefik
  ```

## 4. 步骤二：腾讯云 CLB 后端服务器配置

### 3.1 创建监听器

在腾讯云负载均衡控制台，为你的 CLB 实例添加监听器：

| 监听器    | 监听协议 | 端口 | 证书                       |
| --------- | -------- | ---- | -------------------------- |
| HTTP:80   | HTTP     | 80   | -                          |
| HTTPS:443 | HTTPS    | 443  | 在 CLB 侧绑定域名 SSL 证书 |

### 3.2 绑定后端服务器（关键点）

在两个监听器的「后端服务器」页签中，点击绑定：

1. **选择实例**：勾选你所有的 k3s 节点（Master 和 Agent）
2. **设置端口**：
   - 80 监听器：填写 `31080`
   - 443 监听器：填写 `31080`（CLB 已卸载 SSL，转发到节点走 HTTP 即可）
3. **权重**：全部设为默认的 10

## **5. 步骤四：健康检查与安全组优化**

### **4.1 externalTrafficPolicy: Cluster 请求流程**

1. **外部请求** → 任意节点 NodePort（如 Node1:31080）。
2. **若 Node1 无 Traefik Pod**：流量经 SNAT（源 IP 变为 Node1 IP）跨节点转发至有 Pod 的 Node2。
3. **Traefik Pod 接收**：日志中可见源 IP 为 Node1 IP（或 LB 传递的 X-Forwarded-For 头部保留真实 IP）。
4. **Traefik 反向代理** → 根据 Ingress 规则，可能再次跨节点转发至后端应用 Pod。
5. **回包原路返回。**

**核心结论**：跨节点跳转对延迟影响可忽略；真实 IP 依赖七层 LB 头部注入。

### **4.2 健康检查配置**

建议使用默认的 `externalTrafficPolicy: Cluster`（或显式设置），原因：

- **所有节点健康检查均通过**：CLB 会将流量均匀分发到所有绑定的节点
- **真实 IP 获取**：通过 CLB 的 `X-Forwarded-For` 或 `X-Real-IP` Header 获取，Traefik 访问日志中可配置保留这些字段
- **无单点故障**：任意节点故障不影响服务可用性

**注意**：如需强制保留源 IP（例如内网安全策略），可使用 `Local` 模式，但此时只有运行 Traefik Pod 的节点健康检查会通过。

- **建议检查路径**：`/ping`（Traefik 标准健康检查路径）

### **4.3 安全组加固**

为了安全，不要对公网放行 31080。

节点安全组设置入站规则，仅允许：
- CLB 所在安全组 ID
- CLB 内网 IP 段

访问 TCP 端口 31080。

## **6. 如何手动增加新服务器？**

当你扩容了一个新的 k3s Agent 节点时，只需两步：

1. **初始化节点**：按照正常流程将 Agent 加入 k3s 集群
2. **CLB 后端添加**：
   - 进入腾讯云控制台 → CLB 实例 → 监听器
   - 在 80 和 443 的后端服务器列表里，点击绑定
   - 选中新节点的 IP，端口填入 `31080`，保存

## **7. 总结：优化后的 Ingress 示例**

配置完成后，你的业务 Ingress 只需要处理逻辑路由即可：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  rules:
  - host: www.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

**提示**：如果你需要强制 HTTPS，可以在 Ingress 中加入 Traefik 的 redirect-https 中间件，或者直接在腾讯云 CLB 的 80 监听器配置中开启「强制重定向到 443」。

## CLB 到 CVM 安全组配置 

| 功能状态   | 流量校验路径        | CVM安全组配置                                                   | CLB安全组配置                              | 备注                                       |
| :--------- | :------------------ | :-------------------------------------------------------------- | :----------------------------------------- | :----------------------------------------- |
| **启用**   | 仅CLB安全组         | 无需配置，由系统自动放通CLB流量                                 | 需配置**入站规则**，放通客户端IP和监听端口 | 这是简化配置、集中管理安全策略的推荐方式。 |
| **不启用** | CLB + CVM双重安全组 | 需配置**入站规则**，放通客户端IP（通常为`0.0.0.0/0`）和服务端口 | 需配置**入站规则**，放通客户端IP和监听端口 | 出站规则无需特殊配置。                     |
>
**❓ 为什么“不启用”时 CLB 的出站规则无需特殊配置？**
>
核心原因是腾讯云安全组是 **”有状态” (Stateful)** 的防火墙。  
它会自动跟踪每个已允许的入站连接，并放通其对应的出站响应流量。因此，你只需配置 **入站规则** 来接收请求，CLB 返回响应时所需的出站规则会由系统自动放行，无需手动设置。

## 困惑：CLB → CVM 的出站为何不需要配置？

**CLB → CVM 的转发流量，在 CLB 安全组视角下完全不需要出站规则，原因有三层：**

1. **转发走内网，不触发出站检查**  
   CLB 向后端 CVM 转发请求时，走的是腾讯云 VPC 内网通道。CLB 安全组本质上是防护 CLB 实例公网/内网入口的防火墙，对于 CLB 内部转发到 CVM 的内网流量，**并不经过 CLB 安全组的出站方向规则评估**。

2. **出站流量只指向客户端，且由状态跟踪自动放行**  
   唯一离开 CLB 的出站流量是返回给客户端的响应包。由于安全组具备 **“有状态” (Stateful)** 特性，它会自动记录已允许入站请求的五元组信息，并将对应的响应包自动放行，**无需人工配置出站规则**。

3. **CVM 才是真正的出站规则管控点（如果需要的话）**  
   如果非要说“出站”，那是 CVM 返回响应给 CLB 的过程，而 CVM 的安全组同样基于“有状态”机制自动放行响应，因此 **CVM 的出站规则也无需配置**。

**结论：**  
整个链路中，唯一需要手动配置的只有 **CLB 入站规则** 和 **CVM 入站规则**。所有出站行为（无论是 CLB 还是 CVM 发出的）都因内网转发机制和状态跟踪特性而自动完成，**出站规则一栏可以永远保持为空**。

**📎 参考链接：**

- 腾讯云官方文档 - [配置负载均衡安全组](https://www.tencentcloud.com/zh/document/product/214/14733)（安全组默认放通功能说明）

- 腾讯云官方文档 - [配置负载均衡安全组](https://intl.cloud.tencent.com/zh/document/product/214/14733)（开启/关闭安全组默认放通详解）

- 腾讯云官方文档 - [健康检查异常排查](https://cloud.tencent.com/document/product/214/15461)（安全组默认放通功能检查）

- 腾讯云官方文档 - [后端云服务器的安全组配置](https://cloud.tencent.com.cn/document/product/214/6157)（CVM安全组入站规则配置示例）

- 腾讯云官方文档 - [后端云服务器安全组配置说明](https://doc.fincloud.tencent.cn/tcloud/NetWork/CLB/793445/627745/backendcloudserversecuritygroupconfigurationinstructions)

- 腾讯云官方文档 - [安全组概述](https://cloud.tencent.com.cn/document/product/213/112610)（安全组有状态特性说明）

- 腾讯云官方文档 - [安全组概述](https://www.tencentcloud.com/zh/document/product/213/12452)（入站/出站规则自动放通原理）