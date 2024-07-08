# 脚本说明
> 声明 
> 系列脚本仅供学习交流使用，请勿在生产环境使用，若对于脚本有什么优化的建议，欢迎提交issue
# CheckSSL.sh SSL证书监控脚本
提供使用shell脚本来简单监控站点的SSL证书到期时间，若小于7天，则触发curl动作配合[bark](https://bark.day.app/#/)（该应用貌似仅Iphone可用）进行告警，也可以优化之后支持钉钉、企业微信等告警通道发送告警提醒
## 脚本依赖
依赖于openssl，目前常见的Linux系统默认均包含该程序
## 变量依赖
.env文件应和该脚本文件处于同一目录内，并且文件中应包含变量"bark_key"，例如“bark_key=xxxxxxxxxx”，获取方式参考：[brak使用参考](https://bark.day.app/#/tutorial)
若不需要进行通知告警，则可以手动将脚本中的条件判断语句进行注释
也可以添加其他告警，例如钉钉、企微或其他webhook等告警通道

例如:
```bash
# if [ -f ./.env ]; then
#     source ./.env
# else
#     echo ".env file not found! Manually copy the ".env-template" file to ".env" and add variables as required"
#     exit 1
# fi
······

# get_ssl_expiry_date() {
    ······
#     if [ $days_left -le 7 ]; then
#         curl -s https://api.day.app/$bark_key/SSL监控告警/"$site: 证书在 $days_left 天内过期"?group=jobtest
#     else
#         echo "$site: Certificate expires on $formatted_date"
#     fi
# }
```

# OpenSSL.sh 快速生成自签名证书脚本

## 脚本依赖
依赖于openssl，目前常见的Linux系统默认均包含该程序

## 变量依赖
无

## 使用说明
```bash
./OpenSSL.sh --help

 --ssl-domain: 生成ssl证书需要的主域名，如果是ip访问服务，则可忽略；
 --ssl-trusted-ip: 一般ssl证书只信任域名的访问请求，有时候需要使用ip去访问server，那么需要给ssl证书添加扩展IP，多个IP用逗号隔开；
 --ssl-trusted-domain: 如果想多个域名访问，则添加扩展域名（SSL_TRUSTED_DOMAIN）,多个扩展域名用逗号隔开；
 --ssl-size: ssl加密位数，默认2048；
 --ssl-cn: 国家代码(2个字母的代号),默认CN;
 --ca-cert-recreate: 是否重新创建 ca-cert，ca 证书默认有效期 10 年，创建的 ssl 证书有效期如果是一年需要续签，那么可以直接复用原来的 ca 证书，默认 false;
 使用示例:
 ./create_self-signed-cert.sh --ssl-domain=www.test.com --ssl-trusted-domain=www.test2.com \ 
 --ssl-trusted-ip=1.1.1.1,2.2.2.2,3.3.3.3 --ssl-size=2048 --ssl-date=3650
```

# SystemInfoMonitor.sh 系统基础资源检测
该脚本主要用于检测简单的系统资源利用率，如 磁盘、CPU、内存、带宽利用率等
## 变量依赖
.env文件应和该脚本文件处于同一目录内，并且文件中应包含变量"bark_key"，例如“bark_key=xxxxxxxxxx”，获取方式参考：[brak使用参考](https://bark.day.app/#/tutorial)
若不需要进行通知告警，则可以手动将脚本中的条件判断语句进行注释
也可以添加其他告警，例如钉钉、企微或其他webhook等告警通道

内置变量：

```bash
# 若有更改需求，则在脚本中进行编辑更改
# 设置阈值和灵敏度（可以根据需求修改）
CPU_THRESHOLD=80  # CPU利用率的阈值，超过80%触发curl命令
MEMORY_THRESHOLD=80  # 内存利用率的阈值，超过80%触发curl命令
DISK_THRESHOLD=80  # 磁盘使用率的阈值，超过80%触发curl命令
NETWORK_THRESHOLD=1  # 网络流量的阈值（单位：兆字节），超过1兆字节触发curl命令

# 设置灵敏度阈值和检测时间间隔（可以根据需求修改）
SENSITIVITY_THRESHOLD=3  # 连续超过阈值的次数，达到3次触发curl命令
CHECK_INTERVAL=10  # 检测的时间间隔，单位为秒
```

## 脚本用法
```bash
# 后台持续运行，若需要记录脚本运行日志，则使用追加重定向追加到目标日志文件中，但为了防止持续检测出现占用空间过大可以考虑丢弃运行记录
# 丢弃运行记录如下：
# nohup /PATH/to/SystemInfoMonitor.sh > /dev/null 2>&1
nohup /PATH/to/SystemInfoMonitor.sh >> /var/log/SystemInfoMonitor.log

# 为确保重启服务器之后仍能够正常运行，则需要考虑将运行命令添加到crond任务或者是添加到开机自启脚本（vim /etc/rc.d/rc.local）
# 方法一：编辑rc.local文件将启动命令添加到文件中
vim /etc/rc.d/rc.local
# 已有的命令不要修改
#....
# 在文件末尾添加
nohup /PATH/to/SystemInfoMonitor.sh >> /var/log/SystemInfoMonitor.log
# 或
# nohup /PATH/to/SystemInfoMonitor.sh > /dev/null 2>&1

#方法二：添加定时任务
crontab -e
@reboot /usr/bin/nohup /PATH/to/SystemInfoMonitor.sh >> /var/log/SystemInfoMonitor.log
#或 
# @reboot /usr/bin/nohup nohup /PATH/to/SystemInfoMonitor.sh > /dev/null 2>&1

```

# Q&A
## 已添加.env文件，但仍提示找不到变量文件
如下提示：
`.env file not found! Manually copy the .env-template file to .env and add variables as required`

该问题是由于shell脚本在调用时默认是从当前目录下获取变量信息以及文件的相对路径。由于脚本中对于env文件的判断是`if -f ./.env`和`source ./.env`进行获取变量，所以在 运行的目标 脚本同级目录中添加.env文件之后，若运行路径不是在脚本所在路径下时，则会出现该提示
解决该问题的方法是：
cd切换工作目录到 所用目标脚本的目录中去使用脚本，或者是在工作目录下去创建所需的.env文件，这两个方法同样适用

后续增加了路径判断已彻底解决该问题