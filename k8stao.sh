#!/bin/bash

sudo apk update; sudo apk add kubeadm kubelet kubectl --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

ssh w1 'sudo apk add  kubeadm kubelet --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted'

ssh w2 'sudo apk add  kubeadm kubelet --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted'

sudo kubeadm init --service-cidr 10.98.0.0/24 --pod-network-cidr 10.244.0.0/16  --service-dns-domain=k8s.org --apiserver-advertise-address $(hostname -i) --ignore-preflight-errors=all

sudo rc-update add kubelet default
    #因 Kubelet 是 Daemon 不是 Pod, 需設定為系統自動啟動

mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config
    #將 tao 設成 K8S 管理者

kubectl taint node m1 node-role.kubernetes.io/master:NoSchedule-
    #設定 K8S Master 可以執行 Pod

# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/kungliamg2593/flannel/main/kube-flannel.yml

ssh w1 'sudo rc-update add kubelet default'; ssh w2 'sudo rc-update add kubelet default'

echo -e "\n[crio.image]\ninsecure_registries = [\n  \"quay.k8s.org\"\n]" | sudo tee -a /etc/crio/crio.conf
ssh w1 'echo -e "\n[crio.image]\ninsecure_registries = [\n  \"quay.k8s.org\"\n]" | sudo tee -a /etc/crio/crio.conf'
ssh w2 'echo -e "\n[crio.image]\ninsecure_registries = [\n  \"quay.k8s.org\"\n]" | sudo tee -a /etc/crio/crio.conf'
    #設定crio.conf

export JOIN=$(echo " sudo `kubeadm token create --print-join-command 2>/dev/null`")

ssh w1 "$JOIN"; ssh w2 "$JOIN"
ssh w1 sudo reboot; ssh w2 sudo reboot;sudo reboot

## 重啟後執行，給work主機加上標籤
## kubectl label node w1 node-role.kubernetes.io/worker=; kubectl label node w2 node-role.kubernetes.io/worker=
