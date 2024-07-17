#!/bin/bash

function check_os {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo "Cannot determine the OS type."
        exit 1
    fi
}

function add_nginx_repo {
    case "$OS" in
        ubuntu | debian)
            # Adding Nginx APT repository
            echo "deb http://nginx.org/packages/$OS/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
            curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
            apt update
            ;;
        centos | rhel | almalinux | rockylinux)
            major_version=$(echo $VER | cut -d. -f1)
            # Adding Nginx YUM repository
            cat <<EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/$major_version/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/$major_version/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
            ;;
#         fedora)
#             # Adding Nginx DNF repository
#             cat <<EOF > /etc/yum.repos.d/nginx.repo
# [nginx-stable]
# name=nginx stable repo
# baseurl=https://nginx.org/packages/fedora/\$releasever/\$basearch/
# gpgcheck=1
# enabled=1
# gpgkey=https://nginx.org/keys/nginx_signing.key
# module_hotfixes=true

# [nginx-mainline]
# name=nginx mainline repo
# baseurl=https://nginx.org/packages/mainline/fedora/\$releasever/\$basearch/
# gpgcheck=1
# enabled=0
# gpgkey=https://nginx.org/keys/nginx_signing.key
# module_hotfixes=true
# EOF
#             ;;
        suse | opensuse)
            # Adding Nginx Zypper repository
            cat <<EOF > /etc/zypp/repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/sles/15/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/sles/15/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
            ;;
        alinux)
            major_version=$(echo $VER | cut -d. -f1)
            if [ "$major_version" -eq 2 ]; then
                # Alinux 2 (equivalent to CentOS 7)
                cat <<EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/7/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
            elif [ "$major_version" -eq 3 ]; then
                # Alinux 3 (equivalent to CentOS 8)
                cat <<EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/8/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/8/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
            else
                echo "Unsupported Alinux version"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

function install_nginx {
    case "$OS" in
        ubuntu | debian)
            apt install -y nginx
            ;;
        centos | rhel | almalinux | rockylinux)
            if [ `rpm -qa |grep procps-ng` ]; then
                echo \"procps-ng\" IS Installed
            else
                yum install procps-ng -y
            fi
            major_version=$(echo $VER | cut -d. -f1)
            if [ "$major_version" -ge 8 ]; then
                dnf install -y nginx --repo=nginx-stable
            else
                yum install -y nginx --repo=nginx-stable
            fi
            ;;
        # fedora)
        #     dnf install -y nginx --repo=nginx-stable
        #     ;;
        suse | opensuse)
            zypper install -y nginx --repo=nginx-stable
            ;;
        alinux)
            major_version=$(echo $VER | cut -d. -f1)
            if [ "$major_version" -eq 2 ]; then
                yum install -y nginx --repo=nginx-stable
            elif [ "$major_version" -eq 3 ]; then
                dnf install -y nginx --repo=nginx-stable
            else
                echo "Unsupported Alinux version"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# Checking the OS
check_os

# Adding Nginx repository
add_nginx_repo

# Installing Nginx
install_nginx

# Enabling and starting nginx
if systemctl is-active --quiet nginx; then
    echo "Nginx is already running."
else
    systemctl enable --now nginx
    echo "Nginx has been installed and started."
fi
