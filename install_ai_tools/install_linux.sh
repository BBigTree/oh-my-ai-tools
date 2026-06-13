#!/bin/bash

# ============================================================
# Linux 平台安装函数
# ============================================================

# ---------- 检测 Linux 发行版 ----------
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID}"
        DISTRO_FAMILY="${ID_LIKE:-$ID}"
    elif command -v lsb_release &> /dev/null; then
        DISTRO="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
        DISTRO_FAMILY="${DISTRO}"
    else
        DISTRO="unknown"
        DISTRO_FAMILY="unknown"
    fi

    echo -e "${GREEN}[✓] 检测到发行版: ${DISTRO}${NC}"
}

# ---------- 安装系统依赖 (Linux) ----------
install_system_deps() {
    detect_distro

    local pkg_manager=""
    local install_cmd=""

    case "${DISTRO}" in
        ubuntu|debian|pop|linuxmint|elementary)
            pkg_manager="apt"
            install_cmd="sudo apt-get update -qq && sudo apt-get install -y -qq"
            ;;
        fedora)
            pkg_manager="dnf"
            install_cmd="sudo dnf install -y"
            ;;
        centos|rhel|rocky|alma)
            pkg_manager="yum"
            install_cmd="sudo yum install -y"
            ;;
        arch|manjaro|endeavouros)
            pkg_manager="pacman"
            install_cmd="sudo pacman -S --noconfirm"
            ;;
        opensuse*|sles)
            pkg_manager="zypper"
            install_cmd="sudo zypper install -y"
            ;;
        *)
            echo -e "${YELLOW}[!] 未识别的发行版: ${DISTRO}，跳过系统依赖自动安装${NC}"
            return 0
            ;;
    esac

    echo -e "${CYAN}[*] 使用包管理器: ${pkg_manager}${NC}"

    local pkgs=()
    command -v curl  &> /dev/null || pkgs+=("curl")
    command -v node  &> /dev/null || pkgs+=("nodejs")
    command -v npm   &> /dev/null && pkgs+=("npm")

    if [ ${#pkgs[@]} -gt 0 ]; then
        echo -e "${YELLOW}[!] 缺少系统包: ${pkgs[*]}${NC}"
        echo -ne "    是否自动安装？ [y/n]: "
        read -r auto_install
        if [ "$auto_install" = "y" ] || [ "$auto_install" = "Y" ]; then
            eval "${install_cmd} ${pkgs[*]}"
        fi
    fi
}

# ---------- 检查前置依赖 ----------
check_prerequisites_linux() {
    install_system_deps

    local missing=()
    command -v curl &> /dev/null || missing+=("curl")
    command -v node &> /dev/null || missing+=("node")
    command -v npm  &> /dev/null || missing+=("npm")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[✗] 缺少必要依赖: ${missing[*]}${NC}"
        echo -e "    请手动安装后重试"
        return 1
    fi

    echo -e "${GREEN}[✓] 前置依赖检查通过${NC}"
    echo "    node: $(node --version 2>/dev/null)"
    echo "    npm:  $(npm --version 2>/dev/null)"
    echo "    curl: $(curl --version 2>/dev/null | head -1)"
    return 0
}

# ---------- 安装 Claude Code ----------
install_claude() {
    echo -e "${CYAN}[→] 安装 Claude Code...${NC}"

    if command -v claude &> /dev/null; then
        echo -e "${GREEN}[✓] Claude Code 已安装: $(claude --version 2>/dev/null | head -1)${NC}"
        echo -ne "    是否重新安装？ [y/n]: "
        read -r reinstall
        if [ "$reinstall" != "y" ] && [ "$reinstall" != "Y" ]; then
            return 0
        fi
    fi

    echo -e "${CYAN}    安装方式: npm (全局安装 @anthropic-ai/claude-code)${NC}"
    if npm install -g @anthropic-ai/claude-code@latest; then
        echo -e "${GREEN}[✓] Claude Code 安装成功: $(claude --version 2>/dev/null | head -1)${NC}"
    else
        echo -e "${RED}[✗] Claude Code 安装失败${NC}"
    fi
}

# ---------- 安装 Codex ----------
install_codex() {
    echo -e "${CYAN}[→] 安装 Codex...${NC}"

    if command -v codex &> /dev/null; then
        echo -e "${GREEN}[✓] Codex 已安装: $(codex --version 2>/dev/null | head -1)${NC}"
        echo -ne "    是否重新安装？ [y/n]: "
        read -r reinstall
        if [ "$reinstall" != "y" ] && [ "$reinstall" != "Y" ]; then
            return 0
        fi
    fi

    echo -e "${CYAN}    安装方式: npm (全局安装 @openai/codex)${NC}"
    if npm install -g @openai/codex@latest; then
        echo -e "${GREEN}[✓] Codex 安装成功: $(codex --version 2>/dev/null | head -1)${NC}"
    else
        echo -e "${RED}[✗] Codex 安装失败${NC}"
    fi
}

# ---------- 安装 OpenCode ----------
install_opencode() {
    echo -e "${CYAN}[→] 安装 OpenCode...${NC}"

    if command -v opencode &> /dev/null; then
        echo -e "${GREEN}[✓] OpenCode 已安装: $(opencode --version 2>/dev/null | head -1)${NC}"
        echo -ne "    是否重新安装？ [y/n]: "
        read -r reinstall
        if [ "$reinstall" != "y" ] && [ "$reinstall" != "Y" ]; then
            return 0
        fi
    fi

    echo -e "${CYAN}    安装方式: 官方安装脚本 (curl)${NC}"
    if curl -fsSL https://opencode.ai/install | bash; then
        echo -e "${GREEN}[✓] OpenCode 安装成功: $(opencode --version 2>/dev/null | head -1)${NC}"
    else
        echo -e "${RED}[✗] OpenCode 安装失败${NC}"
    fi
}

# ---------- 安装 Hermes ----------
install_hermes() {
    echo -e "${CYAN}[→] 安装 Hermes...${NC}"

    if command -v hermes &> /dev/null; then
        echo -e "${GREEN}[✓] Hermes 已安装: $(hermes --version 2>/dev/null | head -1)${NC}"
        echo -ne "    是否重新安装？ [y/n]: "
        read -r reinstall
        if [ "$reinstall" != "y" ] && [ "$reinstall" != "Y" ]; then
            return 0
        fi
    fi

    echo -e "${CYAN}    安装方式: npm (全局安装 @anthropic-ai/hermes)${NC}"
    if npm install -g @anthropic-ai/hermes@latest; then
        echo -e "${GREEN}[✓] Hermes 安装成功: $(hermes --version 2>/dev/null | head -1)${NC}"
    else
        echo -e "${RED}[✗] Hermes 安装失败，请确认包名是否正确${NC}"
    fi
}
