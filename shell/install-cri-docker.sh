#!/bin/bash

# # check docker server
if ! type docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
else
    echo 'docker 已安装';
fi

cd /tmp || exit
wget https://github.eli1.top/https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.7/cri-dockerd-0.3.7.amd64.tgz
tar xf cri-dockerd-0.3.7.amd64.tgz
cd cri-dockerd || exit
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd

cat >> /lib/systemd/system/cri-docker.service << EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket

[Service]
Type=notify
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint fd://  --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:3.9
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
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
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

cat >> /lib/systemd/system/cri-docker.socket << EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

systemctl daeload-reload
systemctl enable cri-docker.service --now 