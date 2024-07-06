# 仓库说明
一些常用脚本分享，该系列脚本仅供测试学习交流使用，请勿在生产环境中使用，若环境中包含重要数据，请务必在使用前将数据进行妥善备份。

# shell
shell包含一些Linux常用脚本
[查看介绍](./shell/README.md)

## 脚本使用方式
以CheckSSL.sh脚本为例
```bsah
# 安装git工具 略，请自行使用yum或apt进行安装
#下载脚本到服务器中
git clone https://github.com/db-root/scripts.git
cd scripts/shell
cp .env-template .env
vim .env
# 按照所需添加变量信息
# 运行脚本，例如CheckSSL脚本。
./CheckSSL.sh
# 添加定时检测或持续检测
crontab -e
# 添加以下任务来每天的13点30分运行检测脚本
30 13 * * * bash /<PATH>/<to>/scripts/shell/CheckSSL.sh > /dev/null
```
