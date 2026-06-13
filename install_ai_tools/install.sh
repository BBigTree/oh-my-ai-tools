#!/bin/bash

# ============================================================
# AI 编程助手安装脚本 — 主入口
# 自动检测平台，调用对应平台脚本
# ============================================================
# 注意: 不使用 set -e，本脚本为交互式，每个步骤自行处理错误

# ---------- 颜色定义 ----------
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- 脚本所在目录 ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------- 代理配置 ----------
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
HTTP_PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
SOCKS5_PROXY_URL="socks5://${PROXY_HOST}:${PROXY_PORT}"
USE_PROXY=false

# ---------- 工具列表 ----------
TOOLS=("claude" "codex" "opencode" "hermes")

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

# ---------- 检测平台 ----------
detect_platform() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "${os}" in
        darwin)
            PLATFORM="macos"
            ;;
        linux)
            PLATFORM="linux"
            ;;
        *)
            echo -e "${RED}[✗] 不支持的操作系统: ${os}${NC}"
            exit 1
            ;;
    esac

    case "${arch}" in
        x86_64|amd64)
            ARCH="x64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            echo -e "${RED}[✗] 不支持的架构: ${arch}${NC}"
            exit 1
            ;;
    esac

    echo -e "${GREEN}[✓] 检测到平台: ${PLATFORM} (${ARCH})${NC}"
}

# ---------- 选择要安装的工具 ----------
select_tools() {
    echo ""
    echo -e "${CYAN}[*] 请选择要安装的工具:${NC}"
    echo -e "    ${YELLOW}1)${NC} Claude Code  — Anthropic AI 编程助手"
    echo -e "    ${YELLOW}2)${NC} Codex        — OpenAI AI 编程助手"
    echo -e "    ${YELLOW}3)${NC} OpenCode      — 开源 AI 编程助手"
    echo -e "    ${YELLOW}4)${NC} Hermes        — AI 编程助手"
    echo -e "    ${YELLOW}a)${NC} 全部安装"
    echo -e "    ${YELLOW}q)${NC} 退出"
    echo -ne "    请选择 [1/2/3/4/a/q]: "
    read -r choice

    SELECTED_TOOLS=()

    case "${choice}" in
        1)   SELECTED_TOOLS=("claude") ;;
        2)   SELECTED_TOOLS=("codex") ;;
        3)   SELECTED_TOOLS=("opencode") ;;
        4)   SELECTED_TOOLS=("hermes") ;;
        a|A) SELECTED_TOOLS=("${TOOLS[@]}") ;;
        q|Q) echo -e "${CYAN}[*] 退出${NC}"; exit 0 ;;
        *)   echo -e "${YELLOW}[!] 无效选择，安装全部${NC}"; SELECTED_TOOLS=("${TOOLS[@]}") ;;
    esac
}

# ---------- 主流程 ----------
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}   AI 编程助手安装${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # 1. 检测平台
    detect_platform

    # 2. 询问代理
    if ask_proxy; then
        if check_proxy; then
            setup_proxy
            USE_PROXY=true
        fi
    fi
    echo ""

    # 3. 选择工具
    select_tools

    # 4. 加载平台脚本并执行
    PLATFORM_SCRIPT="${SCRIPT_DIR}/install_${PLATFORM}.sh"
    if [ ! -f "${PLATFORM_SCRIPT}" ]; then
        echo -e "${RED}[✗] 找不到平台脚本: ${PLATFORM_SCRIPT}${NC}"
        exit 1
    fi

    # 导出变量给子脚本使用
    export HTTP_PROXY_URL SOCKS5_PROXY_URL USE_PROXY ARCH
    export GREEN YELLOW RED CYAN BOLD NC

    # shellcheck source=install_macos.sh
    source "${PLATFORM_SCRIPT}"

    # 5. 检查前置依赖
    echo ""
    echo -e "${CYAN}----------------------------------------${NC}"
    "check_prerequisites_${PLATFORM}" || true

    # 6. 逐个安装
    echo ""
    for tool in "${SELECTED_TOOLS[@]}"; do
        echo -e "${CYAN}----------------------------------------${NC}"
        case "${tool}" in
            claude)   install_claude   ;;
            codex)    install_codex    ;;
            opencode) install_opencode ;;
            hermes)   install_hermes   ;;
        esac
    done

    # 7. 清理
    echo ""
    cleanup_proxy

    # 8. 验证
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}   安装验证${NC}"
    echo -e "${CYAN}========================================${NC}"

    for tool in "${SELECTED_TOOLS[@]}"; do
        if command -v "${tool}" &> /dev/null; then
            local_ver=$(${tool} --version 2>/dev/null | head -1)
            echo -e "   ${GREEN}[✓] ${tool} — ${local_ver}${NC}"
        else
            echo -e "   ${RED}[✗] ${tool} — 安装失败或不在 PATH 中${NC}"
        fi
    done

    echo -e "${CYAN}========================================${NC}"
    echo ""
}

main "$@"
