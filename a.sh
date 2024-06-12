#!/bin/bash
apk update; apk upgrade
apk add nano
nano /etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/edge/testing
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/main

apk update && apk add tree unzip curl wget zip grep bash procps util-linux-misc dialog go udev sudo pciutils podman cni-plugin-flannel cni-plugins flannel flannel-contrib-cni kubectl kubelet kubeadm docker uuidgen nfs-utils cri-o cri-tools
echo "root:root" | chpasswd
echo 'PermitRootLogin yes' | tee -a /etc/ssh/ssh_config
echo 'StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config
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
service containerd restart
/etc/init.d/ntpd start
/etc/init.d/docker start
ln -s /usr/libexec/cni/flannel-amd64 /usr/libexec/cni/flannel
echo "net.bridge.bridge-nf-call-iptables=1" |tee -a /etc/sysctl.conf
sysctl net.bridge.bridge-nf-call-iptables=1
rc-update add crio default
echo '
[crio.runtime]

# Overide defaults to not use systemd cgroups.
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"

default_runtime = "crun"

[crio.runtime.runtimes.crun]
runtime_type = "oci"
runtime_root = "/run/crun"

[crio.network]
network_dir = "/etc/cni/net.d/"
plugin_dir = "/opt/cni/bin"
' |tee /etc/crio/crio.conf
echo 'runtime-endpoint: unix:///var/run/crio/crio.sock
image-endpoint: unix:///var/run/crio/crio.sock
timeout: 2
' |tee /etc/crictl.yaml
