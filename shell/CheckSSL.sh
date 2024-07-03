#!/bin/sh
# 加载 .env 文件
# .env文件应和该脚本文件处于同一目录内，并且文件中应包含变量"bark_key"，例如“bark_key=xxxxxxxxxx”
if [ -f .env ]; then
    source .env
else
    echo ".env file not found! Manually copy the ".env-template" file to ".env" and add variables as required"
    exit 1
fi

# 定义站点列表
sites=("aliyun.com" "elisky.cn" "github.com")

# 函数来提取和格式化 SSL 证书的到期日期
get_ssl_expiry_date() {
    # 获取证书信息
    cert_info=$(echo | openssl s_client -servername "$site" -connect "$site:443" -showcerts 2>&1)
    # 提取并格式化证书信息
    expire_date=$(echo "$cert_info" | openssl x509 -noout -dates 2>/dev/null | grep 'notAfter' | sed 's/notAfter=//')
    # 将到期日期转换为 yyyy-MM-dd 格式
    formatted_date=$(date -d "$expire_date" +%Y-%m-%d 2>/dev/null)
    # 输出结果
    # echo "$site: $formatted_date"
        # 获取当前日期
    current_date=$(date +%Y-%m-%d)
    
    # 计算证书到期日期和当前日期之间的天数
    days_left=$(( ( $(date -d "$formatted_date" +%s) - $(date -d "$current_date" +%s) ) / (60*60*24) ))
    
    if [ $days_left -le 7 ]; then
        curl -s https://api.day.app/$bark_key/SSL监控告警/"$site: 证书在 $days_left 天内过期"?group=jobtest
    else
        echo "$site: Certificate expires on $formatted_date"
    fi
}

# 循环遍历所有站点
for site in "${sites[@]}"; do
    get_ssl_expiry_date "$site"
done
