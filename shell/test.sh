#/bin/bash

if [ `rpm -qa |grep procps-ng` ]; then
    echo \"procps-ng\" IS Installed
else
    yum install procps-ng -y
fi
