#!/bin/bash

# 定义一个函数来输出帮助信息
print_help() {
    echo "Usage: $0 [SCRIPT_NAME]"
    echo "Available scripts:"
    echo "  install-docker.sh"
    echo "  install-docker2.sh"
    echo "  install-cri-docker.sh"
    echo "  install-nginx.sh"
    echo "  mng.sh"
    echo "  OpenSSL.sh"
    echo "  SystemInfoMonitor.sh"
    echo "  CheckSSL.sh"
    echo "  README.md (not a script)"
    echo "Example: $0 install-docker.sh"
}

# 检查是否有参数提供
if [ $# -eq 0 ]; then
    print_help
    exit 1
fi

# 根据参数下载相应的脚本
case $1 in
    install-docker)
        curl -sL https://download.elisky.cn/scripts/shell/install-docker.sh -o install-docker.sh
        ;;
    install-docker2)
        curl -sL https://download.elisky.cn/scripts/shell/install-docker2.sh -o install-docker2.sh
        ;;
    install-cri-docker)
        curl -sL https://download.elisky.cn/scripts/shell/install-cri-docker.sh -o install-cri-docker.sh
        ;;
    install-nginx)
        curl -sL https://download.elisky.cn/scripts/shell/install-nginx.sh -o install-nginx.sh
        ;;
    mng)
        curl -sL https://download.elisky.cn/scripts/shell/mng.sh -o mng.sh
        ;;
    OpenSSL)
        curl -sL https://download.elisky.cn/scripts/shell/OpenSSL.sh -o OpenSSL.sh
        ;;
    SystemInfoMonitor)
        curl -sL https://download.elisky.cn/scripts/shell/SystemInfoMonitor.sh -o SystemInfoMonitor.sh
        ;;
    CheckSSL)
        curl -sL https://download.elisky.cn/scripts/shell/CheckSSL.sh -o CheckSSL.sh
        ;;
    *)
        echo "Error: Unknown script '$1'"
        print_help
        exit 1
        ;;
esac

echo "Script downloaded successfully."