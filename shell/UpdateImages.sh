#!/bin/bash

# ============================================================
# Docker Compose 批量升级脚本
# ============================================================

# ==================== 可配置变量 ====================
# Pull 超时时间（秒）
PULL_TIMEOUT=300

# 白名单容器名称（跳过升级），填容器名
# 示例: WHITELIST=("mysql" "postgres-15.2" "php8_4_13")
WHITELIST=()

# 备份根目录
BACKUP_ROOT="/opt/docker-upgrade-backup"
# ====================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

LOG_FILE="$BACKUP_DIR/upgrade.log"
ROLLBACK_SCRIPT="$BACKUP_DIR/rollback.sh"
IMAGE_RECORD="$BACKUP_DIR/image_records.txt"
PULL_RECORD="$BACKUP_DIR/pull_results.txt"
UPGRADE_RECORD="$BACKUP_DIR/upgrade_results.txt"
REPORT_FILE="$BACKUP_DIR/report.txt"

# ============================================================
# 工具函数
# ============================================================

log() {
    local msg="$1"
    local plain_msg
    plain_msg=$(echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${plain_msg}" >> "$LOG_FILE"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}"
}

is_whitelisted_container() {
    local name="$1"
    for w in "${WHITELIST[@]}"; do
        [ "$w" = "$name" ] && return 0
    done
    return 1
}

# 根据镜像名找对应容器，判断是否在白名单
is_whitelisted_image() {
    local image="$1"
    while IFS='|' read -r cname cimage csha; do
        [[ "$cname" == \#* ]] && continue
        if [ "$cimage" = "$image" ] && is_whitelisted_container "$cname"; then
            return 0
        fi
    done < "$IMAGE_RECORD"
    return 1
}

# 获取镜像版本号，优先取 label，其次取 digest 前缀
get_image_version() {
    local image="$1"
    local version=""

    version=$(docker inspect "$image" 2>/dev/null | \
        jq -r '.[0].Config.Labels["org.opencontainers.image.version"] // empty' 2>/dev/null)

    if [ -z "$version" ]; then
        version=$(docker inspect "$image" 2>/dev/null | \
            jq -r '.[0].Config.Labels["version"] // empty' 2>/dev/null)
    fi

    if [ -z "$version" ]; then
        version=$(docker inspect "$image" 2>/dev/null | \
            jq -r '.[0].RepoDigests[0] // empty' 2>/dev/null | \
            grep -o 'sha256:[a-f0-9]*' | cut -c1-19)
    fi

    if [ -z "$version" ]; then
        version=$(docker inspect "$image" 2>/dev/null | \
            jq -r '.[0].Id // empty' 2>/dev/null | cut -c8-19)
    fi

    echo "${version:-unknown}"
}

get_image_id() {
    docker inspect "$1" 2>/dev/null | jq -r '.[0].Id // empty'
}

get_short_id() {
    local full_id="$1"
    echo "${full_id:7:12}"
}

# ============================================================
# 初始化回滚脚本
# ============================================================
cat > "$ROLLBACK_SCRIPT" << 'ROLLBACK_HEADER'
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo "开始回滚所有服务..."
ROLLBACK_HEADER
chmod +x "$ROLLBACK_SCRIPT"

# ============================================================
# 第一步：扫描所有 Compose 文件
# ============================================================
log "${BLUE}>>> 第一步：扫描所有 Docker Compose 文件...${NC}"

COMPOSE_FILES=$(docker inspect $(docker ps -aq) 2>/dev/null | \
    jq -r '.[].Config.Labels["com.docker.compose.project.config_files"] // empty' | \
    sort -u)

if [ -z "$COMPOSE_FILES" ]; then
    log "${RED}未发现任何 docker-compose 管理的容器，退出${NC}"
    exit 1
fi

log "发现以下 Compose 文件："
echo "$COMPOSE_FILES" | tee -a "$LOG_FILE"

# ============================================================
# 第二步：记录当前镜像信息
# ============================================================
log "\n${BLUE}>>> 第二步：记录当前镜像版本（含 sha256）...${NC}"

echo "# 格式: 容器名|镜像名|完整ImageID" > "$IMAGE_RECORD"

docker ps --format '{{.Names}}|{{.Image}}|{{.ID}}' | while IFS='|' read -r cname cimage cid; do
    image_full_id=$(docker inspect "$cid" 2>/dev/null | jq -r '.[0].Image // empty')
    echo "${cname}|${cimage}|${image_full_id}" >> "$IMAGE_RECORD"
done

log "镜像记录完成: $IMAGE_RECORD"

if [ ${#WHITELIST[@]} -gt 0 ]; then
    log "${YELLOW}白名单容器（将跳过升级）: ${WHITELIST[*]}${NC}"
else
    log "白名单为空，全部容器参与升级"
fi

# ============================================================
# 第三步：备份所有 Compose 文件
# ============================================================
log "\n${BLUE}>>> 第三步：备份 Compose 配置文件...${NC}"

echo "$COMPOSE_FILES" | while read -r compose_file; do
    if [ -f "$compose_file" ]; then
        backup_path="${BACKUP_DIR}/compose_backup$(dirname "$compose_file")"
        mkdir -p "$backup_path"
        cp "$compose_file" "$backup_path/"
        log "${GREEN}已备份: $compose_file${NC}"
    else
        log "${YELLOW}文件不存在，跳过: $compose_file${NC}"
    fi
done

# ============================================================
# 第四步：Pull 最新镜像（带超时 + 白名单 + 跳过变量）
# ============================================================
log "\n${BLUE}>>> 第四步：Pull 最新镜像（超时: ${PULL_TIMEOUT}s）...${NC}"

echo "# 格式: compose文件|镜像|pull状态|旧ImageID|新ImageID" > "$PULL_RECORD"

echo "$COMPOSE_FILES" | while read -r compose_file; do
    if [ ! -f "$compose_file" ]; then
        log "${YELLOW}文件不存在，跳过: $compose_file${NC}"
        continue
    fi

    log "\n  处理: $compose_file"

    # 提取镜像，过滤掉含 $ 的未展开变量
    images=$(grep -E '^\s+image:\s+' "$compose_file" | awk '{print $2}' | grep -v '\$')

    if [ -z "$images" ]; then
        log "  ${YELLOW}无有效镜像（可能全为变量引用），跳过${NC}"
        continue
    fi

    for image in $images; do
        # 白名单检查
        if is_whitelisted_image "$image"; then
            log "  ${YELLOW}⏭  白名单跳过: $image${NC}"
            echo "${compose_file}|${image}|WHITELISTED|-|-" >> "$PULL_RECORD"
            continue
        fi

        old_id=$(get_image_id "$image")

        log "  ↓  拉取: $image"

        pull_output=$(timeout "${PULL_TIMEOUT}" docker pull "$image" 2>&1)
        exit_code=$?
        echo "$pull_output" >> "$LOG_FILE"

        if [ $exit_code -eq 124 ]; then
            log "  ${YELLOW}⏱  超时(>${PULL_TIMEOUT}s)跳过: $image${NC}"
            echo "${compose_file}|${image}|TIMEOUT|${old_id}|-" >> "$PULL_RECORD"
        elif [ $exit_code -ne 0 ]; then
            log "  ${RED}✗  Pull 失败: $image${NC}"
            echo "${compose_file}|${image}|PULL_FAILED|${old_id}|-" >> "$PULL_RECORD"
        else
            new_id=$(get_image_id "$image")
            if [ "$old_id" = "$new_id" ] || [ -z "$old_id" ]; then
                log "  ${CYAN}=  无更新: $image${NC}"
                echo "${compose_file}|${image}|NO_UPDATE|${old_id}|${new_id}" >> "$PULL_RECORD"
            else
                log "  ${GREEN}✓  有更新: $image${NC}"
                echo "${compose_file}|${image}|UPDATED|${old_id}|${new_id}" >> "$PULL_RECORD"
            fi
        fi
    done
done

# ============================================================
# 第五步：生成回滚脚本
# ============================================================
log "\n${BLUE}>>> 第五步：生成回滚脚本...${NC}"

while IFS='|' read -r cname cimage csha; do
    [[ "$cname" == \#* ]] && continue
    [ -z "$csha" ] && continue

    compose_file=$(docker inspect $(docker ps -aqf "name=^${cname}$") 2>/dev/null | \
        jq -r '.[0].Config.Labels["com.docker.compose.project.config_files"] // empty' 2>/dev/null)
    [ -z "$compose_file" ] && continue
    compose_dir=$(dirname "$compose_file")

    cat >> "$ROLLBACK_SCRIPT" << EOF
echo -e "\${YELLOW}>>> 回滚: ${cname} (${cimage})\${NC}"
docker tag "${csha}" "${cimage}" 2>/dev/null || true
cd "${compose_dir}" && docker compose up -d
echo -e "\${GREEN}完成: ${cname}\${NC}"
EOF

done < "$IMAGE_RECORD"

echo 'echo -e "${GREEN}=== 全部回滚完成 ===${NC}"' >> "$ROLLBACK_SCRIPT"
log "${GREEN}回滚脚本已生成: $ROLLBACK_SCRIPT${NC}"

# ============================================================
# 第六步：执行升级
# ============================================================
log "\n${BLUE}>>> 第六步：执行升级...${NC}"

echo "# 格式: compose文件|状态|失败原因" > "$UPGRADE_RECORD"

echo "$COMPOSE_FILES" | while read -r compose_file; do
    if [ ! -f "$compose_file" ]; then
        log "${YELLOW}文件不存在，跳过: $compose_file${NC}"
        echo "${compose_file}|SKIPPED|文件不存在" >> "$UPGRADE_RECORD"
        continue
    fi

    compose_dir=$(dirname "$compose_file")
    log "\n  升级: $compose_file"

    upgrade_output=$(cd "$compose_dir" && docker compose up -d 2>&1)
    exit_code=$?
    echo "$upgrade_output" >> "$LOG_FILE"

    if [ $exit_code -eq 0 ]; then
        log "${GREEN}  ✓ 升级成功: $compose_file${NC}"
        echo "${compose_file}|SUCCESS|-" >> "$UPGRADE_RECORD"
    else
        fail_reason=$(echo "$upgrade_output" | grep -iE "^error|Error response" | tail -1 | \
            sed 's/|/\//g' | cut -c1-80)
        [ -z "$fail_reason" ] && fail_reason="未知错误，详见日志"
        log "${RED}  ✗ 升级失败: $compose_file${NC}"
        log "${RED}    原因: ${fail_reason}${NC}"
        echo "${compose_file}|FAILED|${fail_reason}" >> "$UPGRADE_RECORD"
    fi
done

# ============================================================
# 第七步：生成表格报告
# ============================================================
log "\n${BLUE}>>> 第七步：生成升级报告...${NC}"

generate_report() {
    local report="$1"

    # 列宽定义
    local W1=25  # 容器名
    local W2=12  # 升级状态
    local W3=35  # 失败原因
    local W4=20  # 升级前版本
    local W5=20  # 升级后版本

    # 打印横线
    print_sep() {
        printf "+%s+%s+%s+%s+%s+\n" \
            "$(printf '%.0s-' $(seq 1 $((W1+2))))" \
            "$(printf '%.0s-' $(seq 1 $((W2+2))))" \
            "$(printf '%.0s-' $(seq 1 $((W3+2))))" \
            "$(printf '%.0s-' $(seq 1 $((W4+2))))" \
            "$(printf '%.0s-' $(seq 1 $((W5+2))))"
    }

    # 打印一行
    print_row() {
        printf "| %-${W1}s | %-${W2}s | %-${W3}s | %-${W4}s | %-${W5}s |\n" \
            "${1:0:$W1}" "${2:0:$W2}" "${3:0:$W3}" "${4:0:$W4}" "${5:0:$W5}"
    }

    {
        echo "=================================================================="
        echo "  Docker Compose 批量升级报告"
        echo "  生成时间 : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  备份目录 : $BACKUP_DIR"
        echo "  完整日志 : $LOG_FILE"
        echo "=================================================================="
        echo ""

        print_sep
        print_row "容器名称" "升级状态" "备注/失败原因" "升级前版本" "升级后版本"
        print_sep

        # 遍历所有记录的容器
        while IFS='|' read -r cname cimage csha; do
            [[ "$cname" == \#* ]] && continue
            [ -z "$cname" ] && continue

            # 白名单判断
            if is_whitelisted_container "$cname"; then
                old_ver=$(get_image_version "$cimage")
                print_row "$cname" "⏭ 跳过" "白名单容器" "$old_ver" "-"
                continue
            fi

            # 从 pull_results 找该容器镜像的 pull 状态
            pull_status=""
            old_id=""
            new_id=""
            while IFS='|' read -r pfile pimage pstatus pold pnew; do
                [[ "$pfile" == \#* ]] && continue
                if [ "$pimage" = "$cimage" ]; then
                    pull_status="$pstatus"
                    old_id="$pold"
                    new_id="$pnew"
                    break
                fi
            done < "$PULL_RECORD"

            # 从 upgrade_results 找该容器所在 compose 文件的升级状态
            compose_file=$(docker inspect $(docker ps -aqf "name=^${cname}$") 2>/dev/null | \
                jq -r '.[0].Config.Labels["com.docker.compose.project.config_files"] // empty' 2>/dev/null)
            upgrade_status=""
            fail_reason="-"
            if [ -n "$compose_file" ]; then
                while IFS='|' read -r ufile ustatus ureason; do
                    [[ "$ufile" == \#* ]] && continue
                    if [ "$ufile" = "$compose_file" ]; then
                        upgrade_status="$ustatus"
                        [ "$ureason" != "-" ] && fail_reason="$ureason"
                        break
                    fi
                done < "$UPGRADE_RECORD"
            fi

            # 计算升级前后版本显示
            # tag 不是 latest 直接用 tag，是 latest 则尝试取 label version，否则用 sha 短码
            image_tag=$(echo "$cimage" | grep -o ':[^:]*$' | tr -d ':')
            [ -z "$image_tag" ] && image_tag="latest"

            if [ "$image_tag" != "latest" ]; then
                old_ver="$image_tag"
                new_ver="$image_tag"
            else
                # 用 sha 短码区分前后
                old_ver=$(get_short_id "$old_id")
                new_ver=$(get_short_id "$new_id")

                # 优先尝试从 label 获取版本号
                old_label=$(docker inspect "$old_id" 2>/dev/null | \
                    jq -r '.[0].Config.Labels["org.opencontainers.image.version"] // empty' 2>/dev/null)
                new_label=$(docker inspect "$cimage" 2>/dev/null | \
                    jq -r '.[0].Config.Labels["org.opencontainers.image.version"] // empty' 2>/dev/null)

                [ -n "$old_label" ] && old_ver="$old_label"
                [ -n "$new_label" ] && new_ver="$new_label"
            fi

            # 综合状态判断
            if [ "$pull_status" = "PULL_FAILED" ]; then
                status_display="✗ Pull失败"
                fail_reason="Pull镜像失败"
                new_ver="-"
            elif [ "$pull_status" = "TIMEOUT" ]; then
                status_display="⏱ Pull超时"
                fail_reason="Pull超时(>${PULL_TIMEOUT}s)"
                new_ver="-"
            elif [ "$upgrade_status" = "FAILED" ]; then
                status_display="✗ 升级失败"
            elif [ "$upgrade_status" = "SUCCESS" ] && [ "$pull_status" = "UPDATED" ]; then
                status_display="✓ 已升级"
                fail_reason="-"
            elif [ "$upgrade_status" = "SUCCESS" ] && [ "$pull_status" = "NO_UPDATE" ]; then
                status_display="= 无需升级"
                fail_reason="-"
                new_ver="$old_ver"
            elif [ "$upgrade_status" = "SKIPPED" ]; then
                status_display="- 已跳过"
            else
                status_display="? 未知"
            fi

            print_row "$cname" "$status_display" "$fail_reason" "$old_ver" "$new_ver"

        done < "$IMAGE_RECORD"

        print_sep

        echo ""
        echo "=================================================================="
        echo "  统计摘要"
        echo "=================================================================="

        total=$(grep -v '^#' "$IMAGE_RECORD" | grep -c '|' || true)
        upgraded=$(grep 'UPDATED' "$PULL_RECORD" | wc -l | tr -d ' ')
        no_update=$(grep 'NO_UPDATE' "$PULL_RECORD" | wc -l | tr -d ' ')
        pull_failed=$(grep 'PULL_FAILED' "$PULL_RECORD" | wc -l | tr -d ' ')
        pull_timeout=$(grep 'TIMEOUT' "$PULL_RECORD" | wc -l | tr -d ' ')
        whitelisted=$(grep 'WHITELISTED' "$PULL_RECORD" | wc -l | tr -d ' ')
        upgrade_failed=$(grep 'FAILED' "$UPGRADE_RECORD" | wc -l | tr -d ' ')

        echo "  容器总数   : $total"
        echo "  已升级     : $upgraded"
        echo "  无需升级   : $no_update"
        echo "  白名单跳过 : $whitelisted"
        echo "  Pull 失败  : $pull_failed"
        echo "  Pull 超时  : $pull_timeout"
        echo "  升级失败   : $upgrade_failed"
        echo ""
        echo "  回滚脚本   : $ROLLBACK_SCRIPT"
        echo "  完整日志   : $LOG_FILE"
        echo "=================================================================="

    } | tee "$report"
}

generate_report "$REPORT_FILE"

# ============================================================
# 最终汇总输出
# ============================================================
log "\n${BLUE}========== 执行完成 ==========${NC}"
log "备份目录   : $BACKUP_DIR"
log "升级报告   : $REPORT_FILE"
log "回滚脚本   : $ROLLBACK_SCRIPT"
log "完整日志   : $LOG_FILE"
log "\n${YELLOW}查看报告:${NC} cat $REPORT_FILE"
log "${YELLOW}执行回滚:${NC} bash $ROLLBACK_SCRIPT"

# 终端再打印一次报告内容方便直接查看
echo ""
cat "$REPORT_FILE"
