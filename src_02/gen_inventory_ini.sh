#!/bin/bash
cd "$(dirname "$0")"

# Получаем IP из Terraform
MASTER_PUB=$(terraform output -raw master_public_ip)
MASTER_PRIV=$(terraform output -raw master_private_ip)

# Массивы для воркеров (в порядке worker-1, worker-2, worker-3, worker-4)
mapfile -t WORKER_PUBS < <(terraform output -json worker_public_ips | jq -r '.[]')
mapfile -t WORKER_PRIVS < <(terraform output -json worker_private_ips | jq -r '.[]')

# Создаем inventory.ini
cat > ../kubespray/inventory/mycluster/inventory.ini <<EOF
[all]
gribanov-master    ansible_host=158.160.220.8     ip=10.0.2.18
gribanov-worker-1  ansible_host=89.169.141.92     ip=10.0.0.27
gribanov-worker-2  ansible_host=158.160.18.241    ip=10.0.1.4
gribanov-worker-3  ansible_host=158.160.95.137    ip=10.0.1.8
gribanov-worker-4  ansible_host=158.160.5.217     ip=10.0.1.7

[kube_control_plane]
gribanov-master

[etcd]
gribanov-master

[kube_node]
gribanov-worker-1
gribanov-worker-2
gribanov-worker-3
gribanov-worker-4

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOF

echo "✅ inventory.ini создан в ../kubespray/inventory/mycluster/inventory.ini"
