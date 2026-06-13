#!/bin/bash

# ============================================================
# AI 编程助手一键升级脚本
# 工具: claude, codex, opencode, hermes
# 代理: Clash for Windows (mixed-port: 7890)
# ============================================================
# 注意: 不使用 set -e，本脚本为交互式，每个步骤自行处理错误

# ---------- 颜色定义 ----------
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- 代理配置 ----------
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
HTTP_PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
SOCKS5_PROXY_URL="socks5://${PROXY_HOST}:${PROXY_PORT}"
USE_PROXY=false

# ---------- 统计 ----------
UPGRADED=0
SKIPPED=0
FAILED=0

# ---------- 询问用户是否使用代理 ----------
ask_proxy() {
    echo -e "${CYAN}[*] 是否配置代理？${NC} (默认: ${HTTP_PROXY_URL})"
    echo -e "    ${YELLOW}y)${NC} 使用代理"
    echo -e "    ${YELLOW}n)${NC} 不使用代理，直连"
    echo -e "    ${YELLOW}c)${NC} 自定义代理地址"
    echo -ne "    请选择 [y/n/c]: "
    read -r answer

    case "${answer}" in
        y|Y|"")
            echo -e "${CYAN}[*] 使用默认代理: ${HTTP_PROXY_URL}${NC}"
            ;;
        c|C)
            echo -ne "    请输入代理地址 (例如 http://127.0.0.1:7890): "
            read -r custom_proxy
            if [ -n "$custom_proxy" ]; then
                HTTP_PROXY_URL="${custom_proxy}"
                SOCKS5_PROXY_URL="${custom_proxy}"
                echo -e "${CYAN}[*] 使用自定义代理: ${HTTP_PROXY_URL}${NC}"
            else
                echo -e "${YELLOW}[!] 未输入代理地址，使用默认: ${HTTP_PROXY_URL}${NC}"
            fi
            ;;
        n|N)
            echo -e "${CYAN}[*] 不使用代理，直连模式${NC}"
            return 1
            ;;
        *)
            echo -e "${YELLOW}[!] 无效选择，使用默认代理: ${HTTP_PROXY_URL}${NC}"
            ;;
    esac
    return 0
}

# ---------- 检查代理是否可用 ----------
check_proxy() {
    if curl -x "${HTTP_PROXY_URL}" -s --connect-timeout 3 https://www.google.com > /dev/null 2>&1; then
        echo -e "${GREEN}[✓] 代理可用: ${HTTP_PROXY_URL}${NC}"
        return 0
    else
        echo -e "${RED}[✗] 代理不可用: ${HTTP_PROXY_URL}${NC}"
        echo -e "${YELLOW}    请确保代理软件已启动且端口正确${NC}"
        echo -ne "    是否跳过代理，使用直连？ [y/n]: "
        read -r skip
        if [ "$skip" = "y" ] || [ "$skip" = "Y" ]; then
            return 1
        else
            echo -e "${RED}[✗] 终止升级${NC}"
            exit 1
        fi
    fi
}

# ---------- 设置代理环境变量 ----------
setup_proxy() {
    export http_proxy="${HTTP_PROXY_URL}"
    export https_proxy="${HTTP_PROXY_URL}"
    export HTTP_PROXY="${HTTP_PROXY_URL}"
    export HTTPS_PROXY="${HTTP_PROXY_URL}"
    export ALL_PROXY="${SOCKS5_PROXY_URL}"
    export no_proxy="localhost,127.0.0.1,::1"
    echo -e "${GREEN}[✓] 已设置代理环境变量${NC}"
    echo ""
}

# ---------- 清除代理 ----------
cleanup_proxy() {
    if [ "${USE_PROXY}" = true ]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy
        echo -e "${CYAN}[*] 已清除代理环境变量${NC}"
    fi
}

# ---------- 版本比较 (语义化版本) ----------
# 返回: 0=相同, 1=第一个更大, 2=第二个更大
version_compare() {
    local v1="$1" v2="$2"

    # 去掉 v 前缀
    v1="${v1#v}"
    v2="${v2#v}"

    if [ "$v1" = "$v2" ]; then
        return 0
    fi

    local IFS='.'
    read -ra a1 <<< "$v1"
    read -ra a2 <<< "$v2"

    local len=${#a1[@]}
    if [ ${#a2[@]} -gt $len ]; then len=${#a2[@]}; fi

    for ((i = 0; i < len; i++)); do
        local n1=${a1[i]:-0}
        local n2=${a2[i]:-0}
        if [ "$n1" -gt "$n2" ] 2>/dev/null; then
            return 1
        elif [ "$n1" -lt "$n2" ] 2>/dev/null; then
            return 2
        fi
    done
    return 0
}

# ---------- 获取 npm 包最新版本 ----------
get_npm_latest() {
    local pkg="$1"
    local ver
    ver=$(npm view "${pkg}" version 2>/dev/null) || true
    echo "${ver}"
}

# ---------- 获取当前版本 (通用) ----------
get_current_version() {
    local cmd="$1"
    local ver
    ver=$($cmd --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || true
    echo "${ver}"
}

# ---------- 查询 OpenCode 最新版本 (GitHub API) ----------
get_opencode_latest() {
    local ver
    ver=$(curl -sL --connect-timeout 10 \
        "https://api.github.com/repositories/975734319/releases?per_page=10" 2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for r in data:
        tag = r.get('tag_name', '')
        if 'vscode' not in tag.lower() and tag.startswith('v'):
            print(tag)
            break
except:
    pass
" 2>/dev/null) || true
    echo "${ver}"
}

# ---------- 升级单个工具 ----------
upgrade_tool() {
    local name="$1"
    local cmd="$2"
    local latest_ver="$3"
    local upgrade_cmd="$4"

    local current_ver
    current_ver=$(get_current_version "${cmd}")

    if [ -z "$current_ver" ]; then
        echo -e "${YELLOW}[⊘] ${name} — 无法获取当前版本，尝试直接升级${NC}"
        if eval "${upgrade_cmd}"; then
            UPGRADED=$((UPGRADED + 1))
            echo -e "${GREEN}[✓] ${name} 升级成功${NC}"
        else
            FAILED=$((FAILED + 1))
            echo -e "${RED}[✗] ${name} 升级失败${NC}"
        fi
        return
    fi

    if [ -z "$latest_ver" ]; then
        echo -e "${YELLOW}[?] ${name} — 无法获取最新版本 (当前: ${current_ver})，跳过${NC}"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    # 去掉 v 前缀比较
    local clean_latest="${latest_ver#v}"
    local clean_current="${current_ver#v}"

    version_compare "${clean_current}" "${clean_latest}"
    local cmp=$?

    if [ $cmp -eq 0 ]; then
        echo -e "${GREEN}[✓] ${name} — 已是最新版本 (${current_ver})${NC}"
        SKIPPED=$((SKIPPED + 1))
    else
        echo -e "${YELLOW}[↑] ${name} — 需要升级: ${current_ver} -> ${clean_latest}${NC}"
        if eval "${upgrade_cmd}"; then
            local new_ver
            new_ver=$(get_current_version "${cmd}")
            UPGRADED=$((UPGRADED + 1))
            echo -e "${GREEN}[✓] ${name} 升级完成 (${current_ver} -> ${new_ver})${NC}"
        else
            FAILED=$((FAILED + 1))
            echo -e "${RED}[✗] ${name} 升级失败${NC}"
        fi
    fi
}

# ---------- 主流程 ----------
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}   AI 编程助手一键升级${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # 1. 询问是否配置代理
    if ask_proxy; then
        if check_proxy; then
            setup_proxy
            USE_PROXY=true
        fi
    fi
    echo ""

    echo -e "${CYAN}----------------------------------------${NC}"

    # 3. Claude Code
    if command -v claude &> /dev/null; then
        latest=$(get_npm_latest "@anthropic-ai/claude-code")
        upgrade_tool "Claude Code" "claude" "${latest}" "claude update"
    else
        echo -e "${YELLOW}[⊘] Claude Code — 未安装，跳过${NC}"
        SKIPPED=$((SKIPPED + 1))
    fi

    echo -e "${CYAN}----------------------------------------${NC}"

    # 4. Codex
    if command -v codex &> /dev/null; then
        latest=$(get_npm_latest "@openai/codex")
        upgrade_tool "Codex" "codex" "${latest}" "codex update"
    else
        echo -e "${YELLOW}[⊘] Codex — 未安装，跳过${NC}"
        SKIPPED=$((SKIPPED + 1))
    fi

    echo -e "${CYAN}----------------------------------------${NC}"

    # 5. OpenCode
    if command -v opencode &> /dev/null; then
        latest=$(get_opencode_latest)
        upgrade_tool "OpenCode" "opencode" "${latest}" "opencode upgrade"
    else
        echo -e "${YELLOW}[⊘] OpenCode — 未安装，跳过${NC}"
        SKIPPED=$((SKIPPED + 1))
    fi

    echo -e "${CYAN}----------------------------------------${NC}"

    # 6. Hermes
    if command -v hermes &> /dev/null; then
        upgrade_tool "Hermes" "hermes" "" "npm install -g hermes-cli@latest"
    else
        echo -e "${YELLOW}[⊘] Hermes — 未安装，跳过${NC}"
        SKIPPED=$((SKIPPED + 1))
    fi

    # 7. 清理
    echo ""
    cleanup_proxy

    # 8. 汇总
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}   升级汇总${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "   升级成功: ${GREEN}${UPGRADED}${NC}"
    echo -e "   已是最新: ${GREEN}${SKIPPED}${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "   升级失败: ${RED}${FAILED}${NC}"
    fi
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

main "$@"
