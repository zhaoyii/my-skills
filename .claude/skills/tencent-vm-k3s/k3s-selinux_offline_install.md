# K3s 离线安装与 k3s-selinux 问题说明（TencentOS / CentOS）

k3s-selinux 是为 K3s 定制的安全通行证，它通过预设策略规则，让 K3s 能在不关闭 SELinux 强制防护的情况下，合法地获得管理容器、网络和存储所需的系统权限。

## 一、问题原因

在执行 K3s 安装时，如果未跳过 SELinux RPM 安装，可能出现如下错误：

```
Failed to get available versions of k3s-selinux
Cannot download repomd.xml
```

原因如下：

- `INSTALL_K3S_MIRROR=cn` **仅影响 K3s 二进制下载**
- `k3s-selinux` 依赖仍从 `rpm.rancher.io` 下载（国内网络易超时）
- 安装脚本 fallback 到旧版本 `1.2-2`（该版本已下架）

---

## 二、解决方案

### 方案一：手动安装 k3s-selinux（推荐）

在可联网机器下载 RPM：

```bash
wget https://github.com/k3s-io/k3s-selinux/releases/download/v1.6.latest.1/k3s-selinux-1.6-1.el9.noarch.rpm -O /tmp/k3s-selinux.rpm
```

分发到所有节点：

```bash
scp /tmp/k3s-selinux.rpm root@<node>:/tmp/
```

所有节点安装：

```bash
sudo rpm -ivh /tmp/k3s-selinux.rpm
```

---

## 执行安装 k3s 命令

```bash
export INSTALL_K3S_MIRROR=cn
export INSTALL_K3S_SKIP_SELINUX_RPM=true

# 主节点 （server/master）
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | sh -s - \
  --write-kubeconfig-mode 644 \
  --node-name master-01

# agent 节点
export K3S_URL=https://<MASTER_内网_IP>:6443
export K3S_TOKEN=<MASTER_TOKEN> 

# 脚本含义：下载 K3s 安装脚本 → 通过管道执行 → 传入后续参数
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | sh -s - \
  --node-name agent-01 
```

---

## 三、关键参数说明

### 环境变量

| 环境变量                     | 作用                                           |
| ---------------------------- | ---------------------------------------------- |
| INSTALL_K3S_MIRROR           | 指定安装镜像源，`cn` 表示使用国内镜像          |
| INSTALL_K3S_SKIP_DOWNLOAD    | 跳过 K3s 二进制文件下载                        |
| INSTALL_K3S_SKIP_SELINUX_RPM | 跳过 yum 安装 k3s-selinux RPM                  |
| INSTALL_K3S_SKIP_START       | 跳过安装后自动启动 k3s                         |
| K3S_URL                      | K3s Server API 地址（Agent 节点专用）          |
| K3S_TOKEN                    | 集群接入令牌（Agent 节点专用，等同于 --token） |

### 命令行参数

| 参数                      | 作用                               |
| ------------------------- | ---------------------------------- |
| `--write-kubeconfig-mode` | 设置 kubeconfig 文件权限（如 644） |
| `--node-name`             | 指定节点名称                       |
| `--server`                | 指定 K3s Server URL（用于 Agent）  |
| `--token`                 | 指定集群接入令牌（用于 Agent）     |

---

## 四、验证安装

```bash
sudo systemctl status k3s
sudo kubectl get nodes
```

---

## 总结

该问题本质是：

> **k3s 安装脚本的 SELinux 依赖未走镜像源，且默认版本失效**

推荐策略：

- 提前安装 `k3s-selinux`
- 或直接采用“全离线安装”模式，避免所有外网依赖
