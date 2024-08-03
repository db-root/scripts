# Eli-chang开源脚本集合使用说明

欢迎使用Eli-chang的开源脚本集合。以下是每个脚本的详细使用说明、依赖描述、环境变量配置以及参数用法。

## CheckSSL.sh 脚本使用说明

### 脚本功能
检查指定网站的SSL证书到期时间，并在到期前发送告警。

### 脚本依赖
- `openssl`
- `curl`

### 环境变量依赖
- `bark_key`（可选，用于发送bark通知）
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

### 参数用法
- 无特定命令行参数，配置通过`.env`文件或脚本内硬编码。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/CheckSSL.sh
   ```
2. 创建并配置环境变量文件：
   ```bash
   cp .env-template .env
   vim .env
   # 例如设置bark_key
   ```
3. 运行脚本：
   ```bash
   bash CheckSSL.sh
   ```

## install-cri-docker.sh 脚本使用说明

### 脚本功能
安装cri-docker，Docker的CRI运行时。

### 脚本依赖
- `wget`
- `tar`
- `systemd`

### 环境变量依赖
无特定环境变量依赖。

### 参数用法
- 无参数，脚本直接执行安装流程。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/install-cri-docker.sh
   ```
2. 运行脚本：
   ```bash
   bash install-cri-docker.sh
   ```

## install-docker2.sh 脚本使用说明

### 脚本功能
安装或更新Docker到最新版本或指定版本。

### 脚本依赖
- `curl`
- `tar`

### 环境变量依赖
无特定环境变量依赖。

### 参数用法
- `-s` 或 `--skip-confirmation`：跳过版本选择，直接安装最新版本。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/install-docker2.sh
   ```
2. 运行脚本：
   ```bash
   bash install-docker2.sh -s  # 直接安装最新版本
   ```

## install-docker.sh 脚本使用说明

### 脚本功能
安装Docker Engine。

### 脚本依赖
- `curl`

### 环境变量依赖
- `mirror`（可选，用于指定软件源镜像）

### 参数用法
- `--version <VERSION>`：安装指定版本的Docker。
- `--channel <stable|test>`：选择安装通道。
- `--mirror <Aliyun|AzureChinaCloud>`：选择使用哪个镜像源。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/install-docker.sh
   ```
2. 运行脚本：
   ```bash
   bash install-docker.sh --mirror Aliyun
   ```

## install-nginx.sh 脚本使用说明

### 脚本功能
安装Nginx Web服务器。

### 脚本依赖
- 根据系统不同，可能是`apt-get`、`yum`、`zypper`等包管理工具。

### 环境变量依赖
无特定环境变量依赖。

### 参数用法
- 无参数，脚本自动添加Nginx仓库并安装。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/install-nginx.sh
   ```
2. 运行脚本：
   ```bash
   bash install-nginx.sh 
   ```

## mng.sh 脚本使用说明

### 脚本功能
合并Nginx配置文件及其include的文件。

### 脚本依赖
无特定脚本依赖。

### 环境变量依赖
- `CFGPATH`：需要设置为实际的Nginx配置文件路径。

### 参数用法
- 无参数，脚本输出合并后的配置文件到标准输出。

### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/mng.sh
   ```
2. 配置并运行脚本：
   ```bash
   vim mng.sh
   # 设置CFGPATH变量
   bash mng.sh > merged.conf
   ```

## OpenSSL.sh 脚本使用说明

### 脚本功能
生成自签名SSL证书。

### 脚本依赖
- `openssl`

### 环境变量依赖
- `bark_key`（可选，用于发送bark通知）

### 参数用法
```bash
wget https://download.elisky.cn/scripts/shell/OpenSSL.sh

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


### 使用方法
1. 下载脚本：
   ```bash
   wget https://download.elisky.cn/scripts/shell/OpenSSL.sh
   ```
2. 运行脚本：
   ```bash
   bash OpenSSL.sh --ssl-domain www.example.com --ssl-trusted-ip 192.168.1.1,10.0.0.1
   ```

## SystemInfoMonitor.sh 脚本使用说明

### 脚本功能
监控系统信息，包括CPU、内存、磁盘和网络使用率，并在超过阈值时发送告警。

### 脚本依赖
- `curl`

### 环境变量依赖
- `bark_key`：用于发送bark通知。

### 参数用法
- 无参数，脚本使用内置阈值和灵敏度设置。
  
### 内置变量
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

### 使用方法
```bash
wget https://download.elisky.cn/scripts/shell/SystemInfoMonitor.sh
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

请根据您的具体需求，按照上述指南使用相应的脚本。如果需要进一步的帮助或有其他问题，欢迎提交Issue或联系我们。
