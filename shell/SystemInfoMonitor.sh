#!/bin/bash
# 设置阈值和灵敏度（可以根据需求修改）
CPU_THRESHOLD=80  # CPU利用率的阈值，超过80%触发curl命令
MEMORY_THRESHOLD=80  # 内存利用率的阈值，超过80%触发curl命令
DISK_THRESHOLD=80  # 磁盘使用率的阈值，超过80%触发curl命令
NETWORK_THRESHOLD=1  # 网络流量的阈值（单位：兆字节），超过1兆字节触发curl命令

# 设置灵敏度阈值和检测时间间隔（可以根据需求修改）
SENSITIVITY_THRESHOLD=3  # 连续超过阈值的次数，达到3次触发curl命令
CHECK_INTERVAL=10  # 检测的时间间隔，单位为秒
#bark_key=""

# 加载 .env 文件
# .env文件应和该脚本文件处于同一目录内，并且文件中应包含变量"bark_key"，例如“bark_key=xxxxxxxxxx”
# 若不需要使用bark报警，则手动注释掉改内容
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
if [[ -f ./.env ]]; then
    source ./.env

elif [[ -f $SCRIPT_DIR/.env ]]; then
    # shellcheck disable=SC1091
    source $SCRIPT_DIR/.env
else
    echo ".env file not found! Manually copy the '.env-template' file to '.env' and add variables as required"
    exit 1
fi
# 若不需要使用bark报警，则手动注释掉改以上内容

# 设置curl访问的URL（可以根据需求修改）
url_cpu="https://api.day.app/$bark_key/CPU报警/CPU持续利用率过高%0A使用率"
url_memory="https://api.day.app/$bark_key/内存报警/内存持续利用率过高%0A使用率"
url_disk="https://api.day.app/$bark_key/disk报警/disk持续利用率过高%0A使用率"
url_network="https://api.day.app/$bark_key/网络报警/网络持续利用率过高%0A网卡名称"

# 命令功能显示CPU信息，当CPU使用率超过阈值时触发curl命令
function check_cpu() {
    # echo "=== CPU Information ==="
    local cpu_usage=$(top -bn1 | grep "Cpu" | awk '{print $2}' | cut -d'.' -f1)
    # echo "CPU Usage: $cpu_usage%"

    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        # 如果未设置时间戳，则初始化时间戳和计数器
        if [ -z "$timestamp_cpu" ]; then
            timestamp_cpu=$(date +%s)
            counter_cpu=1
        else
            # 检查是否在检测时间间隔内
            local current_timestamp=$(date +%s)
            local time_diff=$((current_timestamp - timestamp_cpu))
            if [ "$time_diff" -le "$CHECK_INTERVAL" ]; then
                ((counter_cpu++))
            else
                # 重置计数器和时间戳
                counter_cpu=1
                timestamp_cpu=$current_timestamp
            fi
        fi

        # 如果连续超过阈值次数达到灵敏度阈值，则触发curl命令
        if [ "$counter_cpu" -ge "$SENSITIVITY_THRESHOLD" ]; then
            # shellcheck disable=SC2006
            echo  "`date +'%Y-%m-%d %H:%m:%S'` === CPU usage exceeds the threshold. Triggering curl command... === $cpu_usage%"
            curl "$url_cpu"%3A"$cpu_usage"%25
            # curl -X POST "$url_cpu" -d "CPU usage exceeds the threshold: $cpu_usage%"
            # 重置计数器和时间戳
            counter_cpu=0
            timestamp_cpu=$(date +%s)
        fi
    fi
}

# 命令功能显示内存信息，当内存使用率超过阈值时触发curl命令
function check_memory() {
    # echo "=== Memory Information ==="
    local memory_usage=$(free | sed -n '2p' | awk '{print $3/$2 * 100}' | cut -d'.' -f1)
    # echo "Memory Usage: $memory_usage%"

    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        # 如果未设置时间戳，则初始化时间戳和计数器
        if [ -z "$timestamp_memory" ]; then
            timestamp_memory=$(date +%s)
            counter_memory=1
        else
            # 检查是否在检测时间间隔内
            local current_timestamp=$(date +%s)
            local time_diff=$((current_timestamp - timestamp_memory))
            if [ "$time_diff" -le "$CHECK_INTERVAL" ]; then
                ((counter_memory++))
            else
                # 重置计数器和时间戳
                counter_memory=1
                timestamp_memory=$current_timestamp
            fi
        fi

        # 如果连续超过阈值次数达到灵敏度阈值，则触发curl命令
        if [ "$counter_memory" -ge "$SENSITIVITY_THRESHOLD" ]; then
            # echo "Memory usage exceeds the threshold. Triggering curl command..."
            echo  "$(date +'%Y-%m-%d %H:%m:%S') === Memory usage exceeds the threshold. Triggering curl command... === $memory_usage%"
            curl $url_memory%3A$memory_usage%25
            # curl -X POST "$url_memory" -d "Memory usage exceeds the threshold: $memory_usage%"
            # 重置计数器和时间戳
            counter_memory=0
            timestamp_memory=$(date +%s)
        fi
    fi
}

# 命令功能显示磁盘空间信息，并在磁盘使用率超过阈值时触发curl命令
function check_disk_space() {
    # echo "=== Disk Space Information ==="
    local disk_usage=$(df | awk '$NF=="/"{printf "%d", $5}')
    # echo "Disk Usage: $disk_usage%"

    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        # 如果未设置时间戳，则初始化时间戳和计数器
        if [ -z "$timestamp_disk" ]; then
            timestamp_disk=$(date +%s)
            counter_disk=1
        else
            # 检查是否在检测时间间隔内
            local current_timestamp=$(date +%s)
            local time_diff=$((current_timestamp - timestamp_disk))
            if [ "$time_diff" -le "$CHECK_INTERVAL" ]; then
                ((counter_disk++))
            else
                # 重置计数器和时间戳
                counter_disk=1
                timestamp_disk=$current_timestamp
            fi
        fi

        # 如果连续超过阈值次数达到灵敏度阈值，则触发curl命令
        if [ "$counter_disk" -ge "$SENSITIVITY_THRESHOLD" ]; then
            # echo "Disk usage exceeds the threshold. Triggering curl command..."
            echo  "`date +'%Y-%m-%d %H:%m:%S'` === Disk usage exceeds the threshold. Triggering curl command... === $disk_usage%"
            curl $url_disk%3A$disk_usage%25
            # curl -X POST "$url_disk" -d "Disk usage exceeds the threshold: $disk_usage%"
            # 重置计数器和时间戳
            counter_disk=0
            timestamp_disk=$(date +%s)
        fi
    fi
}
# 显示网络活动，当网络流量超过阈值时触发curl命令
function check_network_activity() {
    # echo "=== Network Activity ==="
    # 获取网络接口名称，不包括“lo”接口和虚拟接口(例如，“br-”、“veth-”)。
    interfaces=$(ip -o link show | awk '!/lo|br-|veth|docker0/{print $2}' | cut -d':' -f1)

    # 循环通过每个接口
    for interface in $interfaces; do
        # 获取当前接口的当前时间和RX(接收)和TX(发送)字节
        current_timestamp=$(date +%s)
        rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
        tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes")

        # 检查该接口是否被监控过
        if [ -n "${previous_rx_bytes[$interface]}" ] && [ -n "${previous_tx_bytes[$interface]}" ]; then
            # 计算自上次检查以来的时差
            time_diff=$((current_timestamp - timestamp_network[$interface]))

            # 以兆字节每秒(M/s)计算RX和TX速率，避免除以零或负time_diff
            if [ "$time_diff" -gt 0 ]; then
                rx_rate=$((($rx_bytes - previous_rx_bytes[$interface]) / 1048576 / $time_diff))
                tx_rate=$((($tx_bytes - previous_tx_bytes[$interface]) / 1048576 / $time_diff))
            else
                rx_rate=0
                tx_rate=0
            fi

            # echo "Interface: $interface - RX: ${rx_rate} M/s, TX: ${tx_rate} M/s"

            # 检查RX或TX速率是否超过阈值
            if [ "$rx_rate" -gt "$NETWORK_THRESHOLD" ] || [ "$tx_rate" -gt "$NETWORK_THRESHOLD" ]; then
                # 如果接口的灵敏度阈值超过了配置的阈值，则触发curl命令
                if [ -z "${network_counters[$interface]}" ]; then
                    network_counters[$interface]=1
                else
                    ((network_counters[$interface]++))
                fi

                if [ "${network_counters[$interface]}" -ge "$SENSITIVITY_THRESHOLD" ]; then
                    # echo "接口$interface的网络流量超过阈值。触发curl命令……”
                    echo  "`date +'%Y-%m-%d %H:%m:%S'` === Network traffic on interface $interface exceeds the threshold. Triggering curl command... === Interface: $interface - RX: ${rx_rate} M/s, TX: ${tx_rate} M/s"
                    curl "$url_network%3A$interface%0A接收%3A$rx_rate%20M%2Fs%0A发送%3A$tx_rate%20M%2Fs"
                    # curl - x POST "$url_network" -d "接口$interface的网络流量超过阈值:RX - ${rx_rate} M/s, TX - ${tx_rate} M/s"
                    network_counters[$interface]=0
                fi
            else
                # 如果接口低于阈值，则复位接口计数器
                network_counters[$interface]=0
            fi
        fi

        # 记录下一个检查的当前RX和TX字节和时间戳
        previous_rx_bytes[$interface]=$rx_bytes
        previous_tx_bytes[$interface]=$tx_bytes
        timestamp_network[$interface]=$current_timestamp
    done
}

# 定义Main函数
function main() {
    check_cpu
    check_memory
    check_disk_space
    check_network_activity
}

# 在无限循环中执行main函数
echo `date +"%Y-%m-%d %H:%M:%S"`" Check starting..."
while true; do
    main
    echo `date +"%Y-%m-%d %H:%M:%S"`" Pass the check. Start the next check in ten seconds"
    sleep $CHECK_INTERVAL
done
