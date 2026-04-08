#!/bin/bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml << 'EOF'
mirrors:
  docker.io:
    endpoint:
      - "https://mirror.ccs.tencentyun.com"
EOF

# 控制平面重启 k3s 服务
sudo systemctl restart k3s
# 如果有工作节点，重启 k3s-agent 服务
sudo systemctl restart k3s-agent

kubectl get pods,svc,ingress
