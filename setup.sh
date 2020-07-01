#!/bin/sh

USAGE="USAGE: ./setup.sh --name [hostname] --ip [ip] --dns [dns] --passwd --mount --install\n"

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
            sudo passwd
            ;;
        --mount)
            MOUNT=true
            ;;
        --install)
            PACKAGES="git"
            ;;
        --help)
        echo -e $USAGE
        exit 0
        ;;
    esac
    shift
done

if [ -n "$NAME" ]; then
    # Change the hostname
    sudo hostnamectl --transient set-hostname $NAME
    sudo hostnamectl --static set-hostname $NAME
    sudo hostnamectl --pretty set-hostname $NAME
    sudo sed -i s/raspberrypi/${NAME}/g /etc/hosts
fi

if [ -n "$IP" -a -n "$DNS" ]; then
    # Set the static ip
    sudo cat <<EOT >> /etc/dhcpcd.conf
    interface eth0
    static ip_address=${IP}/24
    static routers=${DNS}
    static domain_name_servers=${DNS}
EOT
fi

if [ -n "$MOUNT" ]; then
    # setup mounts and fstab
    sudo mkdir /data
    sudo echo -e "\n192.168.42.11:/volume1/ksfs/k8s_data\t/data\tnfs\tdefaults\t0\t0" >> /etc/fstab

    # setup alias'
    echo "updateme='sudo apt update && sudo apt -y dist-upgrade && sudo -y autoremove'" >> ~/.bash_aliases
fi

if [ -n "$PACKAGES" ]; then
    sudo apt install $PACKAGES
    cd /data/apps/vim/src && sudo make install
fi
