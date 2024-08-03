#!/bin/bash
# 将脚本保存到一个文件内，如：mng.sh，更改CFGPATH变量为实际环境中的配置文件
# 直接运行 bash mng.sh会将合并后的配置输出在屏幕上，可以使用重定向将配置输出到文件内：bash mng.sh > test.conf
# !!! 有些配置文件可能存在相对路径，所以为确保能获取完整的配置文件，请将脚本和 $CFGPATH文件放在同一目录
CFGPATH=/etc/nginx/nginx.conf	##更改为实际环境中的配置文件
IFS=""

read_file(){
    while read -r line
    do
        if [[ $line == *"include"* ]]
        then
            for i in $(echo $line|awk '$1 == "include" {print $2}' | sed 's/;//')
            do
                if [ -f $i ]
                then
                    echo -e "\t# 配置来自 $i"
                    while read -r linein
                    do
                    echo -e "\t$linein"
                    done < $i
                fi
            done
        # echo $line
        else
            echo $line
        fi
    done < $CFGPATH
}
read_file
