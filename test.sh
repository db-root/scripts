#!/bin/bash

# 定义帮助信息
show_help() {
    echo "Usage: $0 [command]"
    echo "Available commands:"
    echo "  install-docker"
    echo "  install-docker2"
    echo "  CheckSSL"
    echo "  install-cri-docker"
    echo "  install-nginx"
    echo "  mng"
    echo "  OpenSSL"
    echo "  SystemInfoMonitor"
}

# 检查是否有参数
if [ $# -eq 0 ]; then
    show_help
else
    case "$1" in
        "install-docker")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/install-docker.sh)
            ;;
        "install-docker2")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/install-docker2.sh)
            ;;
        "CheckSSL")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/CheckSSL.sh)
            ;;
        "install-cri-docker")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/install-cri-docker.sh)
            ;;
        "install-nginx")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/install-nginx.sh)
            ;;
        "mng")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/mng.sh)
            ;;
        "OpenSSL")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/OpenSSL.sh)
            ;;
        "SystemInfoMonitor")
            bash <(curl -sL https://download.elisky.cn/scripts/shell/SystemInfoMonitor.sh)
            ;;
        *)
            show_help
            ;;
    esac
fi