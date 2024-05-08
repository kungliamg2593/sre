#!/bin/bash
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.bridge.bridge-nf-call-iptables=1
echo "br_netfilter" |tee /etc/modules-load.d/k8s.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" |tee /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" |tee /etc/sysctl.conf
cat /etc/fstab | grep -v swap |tee temp.fstab
cat temp.fstab |tee /etc/fstab
rm temp.fstab
swapoff -a
mount --make-rshared /
echo '#!/bin/sh' |tee /etc/local.d/sharemetrics.start
echo "mount --make-rshared /" |tee -a  /etc/local.d/sharemetrics.start
chmod +x /etc/local.d/sharemetrics.start
rc-update add local
uuidgen |sudo tee /etc/machine-id
rc-update add docker
rc-update add ntpd
rc-update add kubelet default
service kubelet restart
/etc/init.d/ntpd start
/etc/init.d/docker start
ln -s /usr/libexec/cni/flannel-amd64 /usr/libexec/cni/flannel
echo "net.bridge.bridge-nf-call-iptables=1" |tee -a /etc/sysctl.conf
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
