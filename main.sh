#!/bin/bash

# 定义帮助信息
show_help() {
    echo "Usage: bash <(curl -sL sc.gbxx.fun) [command] [download|execute] [additional args...]"
    echo "The 'sc.gbxx.fun' domain name is for debugging only. If it cannot be used, use 'download.elisky.cn' instead"
    echo "Available commands:"
    echo "  install-docker (download|execute)"
    echo "  install-docker2 (download|execute)"
    echo "      -s Install the latest version silently"
    echo "  CheckSSL (download)"
    echo "  install-cri-docker (download|execute)"
    echo "  install-nginx (download|execute)"
    echo "  mng (download)"
    echo "  OpenSSL (download|execute)"
    echo "  SystemInfoMonitor (download)"
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
    shift # 移除第一个参数

    if [ "$1" = "download" ] || [ "$1" = "execute" ]; then
        action="$1"
        shift # 移除第二个参数
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
        bash <(curl -sL "$url") "$@"
    fi
fi