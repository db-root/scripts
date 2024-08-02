#!/bin/bash
download_site="download-docker.gbxx.fun"
# 获取Docker版本信息的函数
versions=$(curl -s "https://$download_site/linux/static/stable/$(uname -m)/" | \
    grep -o "docker-.*" | \
    awk -F'\"' '{print $1}' | \
    grep -E '^docker-[0-9]+\.[0-9]+\.[0-9]+\.tgz$' | \
    sed -E 's/^docker-([0-9]+\.[0-9]+\.[0-9]+)\.tgz$/\1/' | \
    sort -V | \
    tail -n 39)
# 检查是否有版本
if [ -z "$versions" ]; then
    echo "No Docker version found"
    exit 1
fi
# 获取最新版本
latest_version=$(echo "$versions" | tail -n 1)
# 处理参数
if [ "\$1" == "-s" ]; then
    version=$latest_version
else
    # 显示版本列表并提示选择
    echo "Available Docker versions:"
    PS3="Select the version to install from 1-40 (press Enter for the latest version): "
    # 将所有版本和最新版本添加到选项中
    options=($(echo $versions) "latest")
    select version in "${options[@]}"; do
        if [[ "$REPLY" -ge "1" && "$REPLY" -le "${#options[@]}" ]]; then
            break
        elif [[ "$version" == "latest" ]]; then
            version=$latest_version
            break
        else
       
                echo "Invalid option $REPLY. Please try again."
        fi
    done
fi
# 显示选择的版本
echo "The Docker version selected is: $version"
