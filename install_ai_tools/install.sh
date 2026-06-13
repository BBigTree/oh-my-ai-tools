#!/bin/bash

# ============================================================
# AI 编程助手安装脚本 (配置驱动)
# 工具列表和安装命令从 tools.json 读取
# ============================================================
# 注意: 不使用 set -e，本脚本为交互式，每个步骤自行处理错误

# ---------- 脚本所在目录 / 配置文件 ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/tools.json"

# ---------- 颜色定义 ----------
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
MUTED='\033[0;2m'
NC='\033[0m'

# ---------- 代理配置 ----------
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
HTTP_PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
SOCKS5_PROXY_URL="socks5://${PROXY_HOST}:${PROXY_PORT}"
USE_PROXY=false

# ---------- 检查配置文件 ----------
if [ ! -f "${CONFIG_FILE}" ]; then
    echo -e "${RED}[✗] 找不到配置文件: ${CONFIG_FILE}${NC}"
    exit 1
fi

# ---------- JSON 查询函数 ----------
# 获取工具列表 (输出: key|name 每行一个)
get_tools() {
    python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    data = json.load(f)
for key, val in data.items():
    name = val.get('name', key)
    cmd = val.get('cmd', key)
    print(f'{key}|{name}|{cmd}')
"
}

# 获取工具的命令名 (用于版本检查)
get_tool_cmd() {
    python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    data = json.load(f)
print(data['${1}'].get('cmd', '${1}'))
"
}

# ---------- 检测当前系统 ----------
detect_system() {
    local os
    os="$(uname -s)"
    case "${os}" in
        Darwin)               SYSTEM="macos" ;;
        Linux)                SYSTEM="linux" ;;
        MINGW*|MSYS*|CYGWIN*) SYSTEM="windows" ;;
        *)                    SYSTEM="linux" ;;
    esac
}

# ---------- 显示系统信息 ----------
show_system_info() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "${os}" in
        Darwin) os="macOS" ;;
        Linux)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                os="${PRETTY_NAME:-Linux}"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) os="Windows" ;;
    esac
    echo -e "${CYAN}[*] 系统信息${NC} ${MUTED}${os} / ${arch}${NC}"
}

# ---------- 获取已安装工具的版本 ----------
get_version() {
    local cmd="$1"
    "${cmd}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# 获取工具在指定系统的安装方式列表 (输出: cmd<TAB>recommended<TAB>deprecated<TAB>note 每行一个)
# 参数: $1 = 工具key, $2 = 系统(macos/linux/windows)
get_methods() {
    python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    data = json.load(f)
for m in data['${1}']['installation'].get('${2}', []):
    cmd = m['cmd']
    rec = '1' if m.get('recommended') else '0'
    dep = '1' if m.get('deprecated') else '0'
    note = m.get('note', '')
    print(f'{cmd}\t{rec}\t{dep}\t{note}')
"
}

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
        echo -ne "    是否跳过代理，使用直连？ [y/n]: "
        read -r skip
        if [ "$skip" = "y" ] || [ "$skip" = "Y" ]; then
            return 1
        else
            echo -e "${RED}[✗] 终止安装${NC}"
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
}

# ---------- 清除代理 ----------
cleanup_proxy() {
    if [ "${USE_PROXY}" = true ]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy
        echo -e "${CYAN}[*] 已清除代理环境变量${NC}"
    fi
}

# ---------- 选择工具 ----------
select_tool() {
    echo ""
    echo -e "${CYAN}[*] 请选择要安装的工具:${NC}"

    TOOL_KEYS=()
    TOOL_NAMES=()
    local i=1
    while IFS='|' read -r key name cmd; do
        TOOL_KEYS+=("${key}")
        TOOL_NAMES+=("${name}")
        local ver
        ver=$(get_version "${cmd}")
        if [ -n "${ver}" ]; then
            echo -e "    ${YELLOW}${i})${NC} ${name} ${GREEN}${ver}${NC}"
        else
            echo -e "    ${YELLOW}${i})${NC} ${name} ${MUTED}未安装${NC}"
        fi
        i=$((i + 1))
    done < <(get_tools)
    echo -e "    ${YELLOW}q)${NC} 退出"
    echo -ne "    请选择: "
    read -r choice

    if [ "${choice}" = "q" ] || [ "${choice}" = "Q" ]; then
        echo -e "${CYAN}[*] 退出${NC}"
        cleanup_proxy
        exit 0
    fi

    if ! [[ "${choice}" =~ ^[0-9]+$ ]] || [ "${choice}" -lt 1 ] || [ "${choice}" -gt ${#TOOL_KEYS[@]} ]; then
        echo -e "${RED}[✗] 无效选择${NC}"
        cleanup_proxy
        exit 1
    fi

    SELECTED_KEY="${TOOL_KEYS[$((choice - 1))]}"
    SELECTED_NAME="${TOOL_NAMES[$((choice - 1))]}"
}

# ---------- 选择安装方式 ----------
select_method() {
    local tool_key="$1"
    local tool_name="$2"

    echo ""
    echo -e "${CYAN}[*] 请选择 ${tool_name} 的安装方式:${NC}"

    METHOD_CMDS=()
    local j=1
    while IFS=$'\t' read -r cmd rec dep note; do
        METHOD_CMDS+=("${cmd}")
        local label=""
        if [ "${rec}" = "1" ]; then
            label="${label} ${GREEN}[推荐]${NC}"
        fi
        if [ "${dep}" = "1" ]; then
            label="${label} ${YELLOW}[已废弃]${NC}"
        fi
        echo -e "    ${YELLOW}${j})${NC} ${cmd}${label}"
        if [ -n "${note}" ]; then
            echo -e "       ${MUTED}↳ ${note}${NC}"
        fi
        j=$((j + 1))
    done < <(get_methods "${tool_key}" "${SYSTEM}")

    if [ ${#METHOD_CMDS[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] 当前系统 (${SYSTEM}) 暂无可用的安装方式${NC}"
        cleanup_proxy
        exit 0
    fi

    echo -ne "    请选择: "
    read -r mchoice

    if ! [[ "${mchoice}" =~ ^[0-9]+$ ]] || [ "${mchoice}" -lt 1 ] || [ "${mchoice}" -gt ${#METHOD_CMDS[@]} ]; then
        echo -e "${RED}[✗] 无效选择${NC}"
        cleanup_proxy
        exit 1
    fi

    SELECTED_CMD="${METHOD_CMDS[$((mchoice - 1))]}"
}

# ---------- 执行安装 ----------
do_install() {
    local name="$1"
    local cmd="$2"
    local install_cmd="$3"

    echo ""
    echo -e "${CYAN}----------------------------------------${NC}"
    echo -e "${CYAN}[→] 安装 ${name}${NC}"
    echo -e "    ${MUTED}${install_cmd}${NC}"
    echo ""

    if eval "${install_cmd}"; then
        echo ""
        if command -v "${cmd}" &> /dev/null; then
            echo -e "${GREEN}[✓] ${name} 安装成功: $(${cmd} --version 2>/dev/null | head -1)${NC}"
        else
            echo -e "${GREEN}[✓] ${name} 安装命令已执行，请重新打开终端或检查 PATH${NC}"
        fi
    else
        echo ""
        echo -e "${RED}[✗] ${name} 安装失败${NC}"
    fi
}

# ---------- 主流程 ----------
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}   AI 编程助手安装${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # 0. 检测系统 + 显示系统信息
    detect_system
    show_system_info

    # 1. 询问代理
    if ask_proxy; then
        if check_proxy; then
            setup_proxy
            USE_PROXY=true
        fi
    fi

    # 2. 选择工具
    select_tool

    # 3. 获取工具命令名
    TOOL_CMD=$(get_tool_cmd "${SELECTED_KEY}")

    # 4. 检查是否已安装
    if command -v "${TOOL_CMD}" &> /dev/null; then
        echo ""
        echo -e "${GREEN}[✓] ${SELECTED_NAME} 已安装: $(${TOOL_CMD} --version 2>/dev/null | head -1)${NC}"
        echo -ne "    是否重新安装？ [y/n]: "
        read -r reinstall
        if [ "${reinstall}" != "y" ] && [ "${reinstall}" != "Y" ]; then
            echo ""
            cleanup_proxy
            exit 0
        fi
    fi

    # 5. 选择安装方式
    select_method "${SELECTED_KEY}" "${SELECTED_NAME}"

    # 6. 执行安装
    do_install "${SELECTED_NAME}" "${TOOL_CMD}" "${SELECTED_CMD}"

    # 7. 清理
    echo ""
    cleanup_proxy
    echo ""
}

main "$@"
