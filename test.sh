#!/bin/bash

# 定义帮助信息
show_help() {
    echo "Usage: $0 [command] [download|execute]"
    echo "Available commands:"
    echo "  install-docker"
    echo "  install-docker2"
    echo "  CheckSSL"
    echo "  install-cri-docker"
    echo "  install-nginx"
    echo "  mng"
    echo "  OpenSSL"
    echo "  SystemInfoMonitor"
    echo "Options:"
    echo "  download - Download the script but do not execute it."
    echo "  execute - Execute the script after downloading it (default)."
}

# 检查是否有参数
if [ $# -lt 1 ]; then
    show_help
else
    command="$1"
    action="execute" # 默认操作是执行
    if [ $# -eq 2 ]; then
        action="$2"
    fi

    case "$command" in
        "install-docker")
            url="https://download.elisky.cn/scripts/shell/install-docker.sh"
            ;;
        "install-docker2")
            url="https://download.elisky.cn/scripts/shell/install-docker2.sh"
            ;;
        "CheckSSL")
            url="https://download.elisky.cn/scripts/shell/CheckSSL.sh"
            ;;
        "install-cri-docker")
            url="https://download.elisky.cn/scripts/shell/install-cri-docker.sh"
            ;;
        "install-nginx")
            url="https://download.elisky.cn/scripts/shell/install-nginx.sh"
            ;;
        "mng")
            url="https://download.elisky.cn/scripts/shell/mng.sh"
            ;;
        "OpenSSL")
            url="https://download.elisky.cn/scripts/shell/OpenSSL.sh"
            ;;
        "SystemInfoMonitor")
            url="https://download.elisky.cn/scripts/shell/SystemInfoMonitor.sh"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac

    if [ "$action" = "download" ]; then
        curl -o "${command}.sh" -sL "$url"
    else
        bash <(curl -sL "$url")
    fi
fi