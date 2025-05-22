#!/bin/bash
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

help() {
	cat <<-EOF
	采用预编译包安装docker以及docker-compose插件.
	已适配Debian、Ubuntu、Rhel、Centos、Alibaba Cloud Linux、Anolis
	EOF
}

apt-AddRepo() {
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg -y
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
}

yum-AddRepo() {
	sudo yum install -y yum-utils
	yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
}

apt-install() {
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
}
yum-install() {
	yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
}

enable-server() {
	systemctl enable --now docker
}

add-daemonfile() {
	mkdir -p /etc/docker
	cat > /etc/docker/daemon.json <<EOF
{
	"registry-mirrors": [
		"https://docker.eli1.top",
		"https://docker.m.daocloud.io"
	]
}
EOF
}
do_install() {
	if command_exists yum;then
	 	yum-AddRepo
		yum-install
	fi
	if command_exists apt;then
		apt-AddRepo
		apt-install
	fi
	add-daemonfile
	enable-server
	docker version
}

do_install