#!/bin/bash
echo "br_netfilter" |sudo tee /etc/modules-load.d/k8s.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" |sudo tee /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" |sudo tee /etc/sysctl.conf
modprobe br_netfilter
cat /etc/fstab | grep -v swap |sudo tee temp.fstab
cat temp.fstab |sudo tee /etc/fstab
rm temp.fstab
swapoff -a
mount --make-rshared /
echo '#!/bin/sh' |sudo tee /etc/local.d/sharemetrics.start
echo "mount --make-rshared /" |sudo tee -a  /etc/local.d/sharemetrics.start
chmod +x /etc/local.d/sharemetrics.start
rc-update add local
uuidgen |sudo tee /etc/machine-id
rc-update add docker
rc-update add kubelet
rc-update add ntpd
/etc/init.d/ntpd start
/etc/init.d/docker start
ln -s /usr/libexec/cni/flannel-amd64 /usr/libexec/cni/flannel
echo "net.bridge.bridge-nf-call-iptables=1" |sudo tee -a /etc/sysctl.conf
sysctl net.bridge.bridge-nf-call-iptables=1
rc-update add crio default
echo '
[crio.network]
network_dir = "/etc/cni/net.d/"
plugin_dir = "/opt/cni/bin"
' | tee /etc/crio/crio.conf
echo 'runtime-endpoint: unix:///var/run/crio/crio.sock
image-endpoint: unix:///var/run/crio/crio.sock
timeout: 2
' > /etc/crictl.yaml
