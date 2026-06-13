# AI 编程助手安装脚本

自动检测平台并安装 AI 编程 CLI 工具。

## 支持的平台

| 平台 | 脚本文件 | 包管理器 |
|------|---------|---------|
| macOS (arm64 / x64) | `install_macos.sh` | Homebrew / npm |
| Linux (arm64 / x64) | `install_linux.sh` | apt / dnf / yum / pacman / zypper |

## 支持的工具

| 工具 | 安装方式 | 前置依赖 |
|------|---------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `npm install -g @anthropic-ai/claude-code` | Node.js >= 18 |
| [Codex](https://github.com/openai/codex) | `npm install -g @openai/codex` | Node.js >= 16 |
| [OpenCode](https://github.com/sst/opencode) | `curl -fsSL https://opencode.ai/install \| bash` | curl |
| Hermes | `npm install -g @anthropic-ai/hermes` | Node.js >= 16 |

## 快速开始

```bash
# 赋予执行权限（首次）
chmod +x install.sh install_macos.sh install_linux.sh

# 运行
./install.sh
```

## 工作流程

```
1. 检测平台 (macOS / Linux + 架构)
       ↓
2. 询问是否配置代理 (默认 / 自定义 / 直连)
       ↓
3. 选择要安装的工具
   ├─ 1) Claude Code
   ├─ 2) Codex
   ├─ 3) OpenCode
   ├─ 4) Hermes
   ├─ a) 全部安装
   └─ q) 退出
       ↓
4. 加载平台脚本 → 检查前置依赖 → 逐个安装
       ↓
5. 已安装的工具询问是否重新安装
       ↓
6. 清除代理 → 验证安装结果
```

## 输出示例

```
========================================
   AI 编程助手安装
========================================

[✓] 检测到平台: macos (arm64)
[*] 是否配置代理？ (默认: http://127.0.0.1:7890)
    y) 使用代理
    n) 不使用代理，直连
    c) 自定义代理地址
    请选择 [y/n/c]: y
[✓] 代理可用: http://127.0.0.1:7890
[✓] 已设置代理环境变量

[*] 请选择要安装的工具:
    1) Claude Code
    2) Codex
    3) OpenCode
    4) Hermes
    a) 全部安装
    q) 退出
    请选择 [1/2/3/4/a/q]: a

----------------------------------------
[→] 安装 Claude Code...
    安装方式: npm (全局安装 @anthropic-ai/claude-code)
[✓] Claude Code 安装成功: 2.1.177
----------------------------------------
[→] 安装 Codex...
[✓] Codex 已安装: 0.135.0
    是否重新安装？ [y/n]: n
----------------------------------------
...

========================================
   安装验证
========================================
   [✓] claude — 2.1.177
   [✓] codex — 0.135.0
   [✓] opencode — 1.17.3
========================================
```

## 文件结构

```
install_ai_tools/
├── install.sh          # 主入口：检测平台，询问代理，选择工具，调度安装
├── install_macos.sh    # macOS 安装函数
├── install_linux.sh    # Linux 安装函数（自动识别发行版）
└── README.md           # 本文档
```

## Linux 发行版支持

| 发行版 | 包管理器 |
|--------|---------|
| Ubuntu / Debian / Pop!_OS / Linux Mint | apt |
| Fedora | dnf |
| CentOS / RHEL / Rocky / Alma | yum |
| Arch / Manjaro / EndeavourOS | pacman |
| openSUSE / SLES | zypper |

## 注意事项

- 脚本运行结束后会自动清除代理环境变量
- 已安装的工具会提示是否重新安装，默认跳过
- Linux 下缺少依赖时会提示自动安装（需要 sudo 权限）
- macOS 下缺少依赖时可通过 Homebrew 自动安装
