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