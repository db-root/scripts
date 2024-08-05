#!/bin/bash
download_site="download-docker.gbxx.fun"
# 获取所有 Docker 版本
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
install_rely_on() {
    if ! type tar >/dev/null 2>&1;then
        echo "tar is installed."
    else
        echo "tar is not installed. Installing..."
        yum install -y tar || apt install -y tar || zypp install -y tar || pacman -S tar
    fi
}

download_docker() {
# 获取最新版本
latest_version=$(echo "$versions" | tail -n 1)

    # 处理参数
    if [ "$1" == "-s" ]; then
        version=$latest_version
    else
        # 显示版本列表并提示选择
        echo "Available Docker versions:"
        PS3="Select the version to install from 1-40 (press Enter for the latest version): "
        # 将所有版本和最新版本添加到选项中
        # shellcheck disable=SC2207
        # shellcheck disable=SC2116
        # shellcheck disable=SC2086
        options=($(echo $versions) "latest")
        select version in "${options[@]}"; do
            if [[ "$REPLY" -ge "1" && "$REPLY" -le "${#options[@]}" ]]; then
                if [ "$version" == "latest" ]; then
                    version=$latest_version
                fi
                break
            else
                    echo "Invalid option $REPLY. Please try again."
            fi
        done
    fi

# 显示选择的版本
echo "The Docker version selected is: $version"

# 构建下载链接
url="https://download-docker.gbxx.fun/linux/static/stable/$(uname -m)/docker-${version}.tgz"

# 执行下载
echo "Downloading Docker ${version}..."
curl -LO "$url"

# 下载完成提示
echo "Docker ${version} download completes。"
}

create_docker_service() {

cat <<EOF > /usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service time-set.target
Wants=network-online.target containerd.service
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /usr/lib/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

cat <<EOF > /usr/lib/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target
[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999
[Install]
WantedBy=multi-user.target
EOF

}

docker_daemon_install() {
    sudo mkdir -p /etc/docker
	sudo chmod 0755 /etc/docker
    sudo sh -c 'cat > /etc/docker/daemon.json' <<EOF
{
	"registry-mirrors": [
		"https://docker.gbxx.fun"
	]
}
EOF
}

main() {
    install_rely_on
    download_docker "$@"
    if [ -f "docker-$version.tgz" ]; then
    # 解压文件
    tar -xzf "docker-$version.tgz"
    # 移动文件到 /usr/bin
    mv docker/* /usr/bin/
    # 删除临时文件
    rm -rf docker "docker-$version.tgz"
    # 创建 docker.service 文件
    create_docker_service
    # 提示安装成功
    echo "Docker ${version} installation completed."
    docker_daemon_install
    # 启动docker服务
    systemctl daemon-reload
    systemctl enable containerd.service --now
    systemctl enable docker.service --now
    sudo groupadd docker
	sudo usermod -aG docker $$USER
	newgrp docker
    else
        echo "Failed to download Docker ${version}."
    fi
}

main "$@"

# 测试下载模块
# test(){
#     install_rely_on
#     install_docker $@
# }

# test $@