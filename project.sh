你的儲存空間用量已達 86%。 … 儲存空間用盡後，你將無法上傳新檔案。瞭解詳情
要用的套件安裝.txt
擁有存取權的使用者

系統屬性
類型
文字
大小
5 KB
儲存空間使用量
9 KB
位置
SRE課程專題-第一組
擁有者
吳浩鈞
上次修改日期
吳浩鈞於 下午5:40修改過
上次開啟日期
我於 下午5:42開啟過
建立日期
2022年6月16日
沒有說明
檢視者可以下載
#!/bin/bash

while true
  do
  clear
  echo -e "1.K8S一鍵部屬\n2.Metallb\n3.nginx ingress\n4.Grafana\n5.Prometheus\n6.Metrics Server\n7.exit"
  echo ""

  read -p "請輸入要安裝的數字: " ans
  case $ans in

  "1")
    sudo apk update; sudo apk add kubeadm kubelet kubectl --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

    ssh w1 'sudo apk add  kubeadm kubelet --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted'

    ssh w2 'sudo apk add  kubeadm kubelet --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted'

    sudo kubeadm init --service-cidr 10.98.0.0/24 --pod-network-cidr 10.244.0.0/16  --service-dns-domain=k8s.org --apiserver-advertise-address $IP

    sudo rc-update add kubelet default
        #因 Kubelet 是 Daemon 不是 Pod, 需設定為系統自動啟動

    mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config
        #將 bigred 設成 K8S 管理者

    kubectl taint node m1 node-role.kubernetes.io/master:NoSchedule-
        #設定 K8S Master 可以執行 Pod

    # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f https://raw.githubusercontent.com/kungliamg2593/flannel/main/kube-flannel.yml

    ssh w1 'sudo rc-update add kubelet default'; ssh w2 'sudo rc-update add kubelet default'

    export JOIN=$(echo " sudo `kubeadm token create --print-join-command 2>/dev/null`")

    ssh w1 "$JOIN"; ssh w2 "$JOIN"
    ssh w1 sudo reboot; ssh w2 sudo reboot;sudo reboot
  ;;

  "2")
    # install Local Path Provisioner
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml

    # install MetalLB
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

    # 建立「ConfigMap」來設定MetalLB,namespace:metallb-system
    # LoadBalancer 服務在 192.168.61.220-192.168.61.230 預先指定的 IP 位址池
echo '
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: mlb1
      protocol: layer2
      addresses:
      - 192.168.61.220-192.168.61.230' | kubectl apply -f - &>/dev/null

    sleep 10
    echo "MetalLB 安裝完成"
    sleep 1
    continue
  ;;

  "3")
    # install nginx ingress
    wget -O - https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/cloud/deploy.yaml | sed 's|name: nginx|name: ig1|g' | kubectl apply -f -

    sleep 10
    echo "nginx ingress 安裝完成"
    sleep 1
    continue
  ;;

  "4")
    # 新建gf namespace
    kubectl create ns gf

    # install grafana
    kubectl apply -f https://web.flymks.com/grafana/v1/grafana.yaml

    sleep 10
    echo "Grafana 安裝完成"
    sleep 1
    continue
  ;;

  "5")
    # 安裝 Helm 3
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

    helm repo add stable https://charts.helm.sh/stable

    helm repo update

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    helm repo update

    helm show values prometheus-community/kube-prometheus-stack

    echo '## Using default values from https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
##
grafana:
  enabled: true
  adminPassword: admin
  ingress:
    enabled: true
    ingressClassName: ig1
    hosts:
      - pgf.k8s.org
    path: /
  persistence:
    enabled: true
    storageClassName: rook-cephfs
    accessModes: ["ReadWriteMany"]
    resources:
      requests:
        storage: 10Gi
  env:
    GF_INSTALL_PLUGINS: grafana-clock-panel,ryantxu-ajax-panel,yesoreyeram-infinity-datasource

## Deploy a Prometheus instance
##
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: rook-cephfs
          accessModes: ["ReadWriteMany"]
          resources:
            requests:
              storage: 20Gi

## Configuration for alertmanager
## ref: https://prometheus.io/docs/alerting/alertmanager/
##
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: rook-cephfs
          accessModes: ["ReadWriteMany"]
          resources:
            requests:
              storage: 20Gi ' > values.yaml

    # 替換內容
    sed -i 's|rook-cephfs|local-path|g' values.yaml
    sed -i 's|ReadWriteMany|ReadWriteOnce|g' values.yaml

    # 使用Helm安裝Prometheus
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --values values.yaml

    sleep 10
    echo "Prometheus 安裝完成"
    sleep 1
    continue
  ;;

  "6")
    kubectl apply -f https://raw.githubusercontent.com/kungliamg2593/flannel/main/components.yaml

    sleep 10
    echo "Metrics Server 安裝完成"
    sleep 1
    continue
  ;;

  "7")
    echo "bye!"
    break
  ;;
  esac
done
