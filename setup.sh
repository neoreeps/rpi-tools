#!/bin/sh

USAGE="USAGE: ./setup.sh --name [hostname] --ip [ip] --dns [dns] --passwd --mount --install --reboot\n
    \n\tname\tthe hostname of this machine
    \n\tip\tthe new ip address of this machine (set to eth0)
    \n\tdns\tthe dns name server (usually .1 of this subnet)
    \n\tpasswd\tprompts to set root and pi passwds
    \n\tmount\tupdates /etc/fstab and mounts /data
    \n\tinstall\tinstalls packages
    \n\treboot\treboot after install"

if [ `whoami` != root ]; then echo "must run as root"; exit 1; fi
if [ $# -lt 1 ]; then echo $USAGE; fi

while test $# -gt 0; do
    case "$1" in
        --name)
            NAME=$2
            shift
            ;;
        --ip)
            IP=$2
            shift
            ;;
        --dns)
            DNS=$2
            shift
            ;;
        --passwd)
            passwd
            passwd pi
            ;;
        --mount)
            MOUNT=true
            ;;
        --install)
            PACKAGES="vim git python3-pip docker.io apt-transport-https curl"
            ;;
        --reboot)
            REBOOT="true"
            ;;
        --help)
        echo -e $USAGE
        exit 0
        ;;
    esac
    shift
done

########################################
# HOSTNAME
########################################

if [ -n "$NAME" ]; then
    # Change the hostname
    hostnamectl --transient set-hostname $NAME
    hostnamectl --static set-hostname $NAME
    hostnamectl --pretty set-hostname $NAME
    sed -i s/raspberrypi/${NAME}/g /etc/hosts
fi

########################################
# NETWORK
########################################

if [ -n "$IP" -a -n "$DNS" ]; then
    # Set the static ip
    cat <<EOT >> /etc/dhcpcd.conf
interface eth0
static ip_address=${IP}/24
static routers=${DNS}
static domain_name_servers=${DNS}
EOT
    cat <<EOT >> /etc/hosts
192.168.42.30   k8sn30
192.168.42.31   k8sn31
192.168.42.32   k8sn32
192.168.42.33   k8sn33
192.168.42.34   k8sn34
EOT
fi

########################################
# MOUNTS
########################################

if [ -n "$MOUNT" ]; then
    # setup mounts and fstab
    mkdir -p /data
    grep ksfs /etc/fstab > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "\n192.168.42.11:/volume1/ksfs/k8s_data\t/data\tnfs\tdefaults\t0\t0" >> /etc/fstab
    fi
    mount -a
    if [ $? -ne 0 ]; then echo "mount failed with $?"; exit 1; fi
    if [ -e /home/pi -a ! -L /home/pi ]; then
        mv /home/pi /home/pi.bak
        ln -s /data/pi-home /home/pi
    fi
fi

########################################
# INSTALLATION
########################################

if [ -n "$PACKAGES" ]; then
    apt update && apt install -y $PACKAGES && apt -y autoremove
    cd /data/apps/vim/src && make install
    ln -s /usr/share/vim/vim81 /usr/share/vim/vim80
    addgroup pi docker
    if [ ! -e /etc/docker/daemon.json ]; then
        cat <<EOT > /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOT
        sed -i '$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1/' /boot/cmdline.txt
        if [ ! -e /etc/sysctl.d/k8s.conf ]; then
            cat <<EOT > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOT
            sysctl --system
        fi
    fi
    if [ ! -e /etc/apt/sources.list.d/kubernetes.list ]; then
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        cat <<EOT > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOT
        apt update && apt install -y kubelet kubeadm kubectl
        apt-mark hold kubelet kubeadm kubectl
    fi
fi

########################################
# REBOOT
########################################

if [ -n "$REBOOT" ]; then reboot; fi
