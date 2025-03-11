#!/usr/bin/env zsh

# 获取Windows虚拟网卡的IP地址
WIN_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }')

if [[ -z "$WIN_IP" ]]; then
    echo "无法获取Windows虚拟网卡IP地址"
else
    export http_proxy="http://${WIN_IP}:7890"
    export https_proxy="http://${WIN_IP}:7890"
    export ftp_proxy="http://${WIN_IP}:7890"
    export no_proxy="localhost,127.0.0.1"
fi

