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
            echo "https://download.elisky.cn/scripts/shell/install-docker.sh"
            ;;
        "install-docker2")
            echo "https://download.elisky.cn/scripts/shell/install-docker2.sh"
            ;;
        "CheckSSL")
            echo "https://download.elisky.cn/scripts/shell/CheckSSL.sh"
            ;;
        "install-cri-docker")
            echo "https://download.elisky.cn/scripts/shell/install-cri-docker.sh"
            ;;
        "install-nginx")
            echo "https://download.elisky.cn/scripts/shell/install-nginx.sh"
            ;;
        "mng")
            echo "https://download.elisky.cn/scripts/shell/mng.sh"
            ;;
        "OpenSSL")
            echo "https://download.elisky.cn/scripts/shell/OpenSSL.sh"
            ;;
        "SystemInfoMonitor")
            echo "https://download.elisky.cn/scripts/shell/SystemInfoMonitor.sh"
            ;;
        *)
            show_help
            ;;
    esac
fi