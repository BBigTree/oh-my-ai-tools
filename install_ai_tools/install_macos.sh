#!/bin/bash

# ============================================================
# macOS 平台安装函数
# ============================================================

# ---------- 检查前置依赖 ----------
check_prerequisites_macos() {
    local missing=()

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    if ! command -v node &> /dev/null; then
        missing+=("node (建议通过 brew install node 或安装 nvm)")
    fi

    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}[!] 缺少前置依赖:${NC}"
        for dep in "${missing[@]}"; do
            echo -e "    ${RED}- ${dep}${NC}"
        done
        echo ""
        echo -ne "    是否尝试自动安装缺少的依赖？ [y/n]: "
        read -r auto_install
        if [ "$auto_install" = "y" ] || [ "$auto_install" = "Y" ]; then
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}[✗] 未安装 Homebrew，请先安装: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
                return 1
            fi
            for dep in "${missing[@]}"; do
                case "$dep" in
                    curl) brew install curl ;;
                    node*) brew install node ;;
                    npm)  ;; # npm 随 node 一起安装
                esac
            done
        else
            return 1
        fi
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
