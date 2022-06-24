#!/bin/bash
cat /etc/hosts | ssh w1 "sudo sh -c 'cat >/etc/hosts'"
cat /etc/hosts | ssh w2 "sudo sh -c 'cat >/etc/hosts'"
echo "w1"|ssh w1 "sudo sh -c 'cat >/etc/hostname'"
echo "w2"|ssh w2 "sudo sh -c 'cat >/etc/hostname'"
