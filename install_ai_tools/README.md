# AI 编程助手安装脚本

配置驱动的 AI 编程 CLI 工具安装器，工具列表和安装命令从 `tools.json` 读取。

## 支持的工具

| 工具 | 命令 | 仓库 |
|------|------|------|
| [Claude Code](https://github.com/anthropics/claude-code) | `claude` | anthropics/claude-code |
| [Codex](https://github.com/openai/codex) | `codex` | openai/codex |
| [OpenCode](https://github.com/anomalyco/opencode) | `opencode` | anomalyco/opencode |
| [Hermes](https://github.com/NousResearch/hermes-agent) | `hermes` | NousResearch/hermes-agent |

## 支持的系统

- **macOS** — curl 安装脚本 / Homebrew / npm
- **Linux** — curl 安装脚本 / npm
- **Windows** — PowerShell / winget / scoop / choco / npm

脚本自动检测当前系统，仅展示该系统可用的安装方式。

## 快速开始

```bash
# 赋予执行权限（首次）
chmod +x install.sh

# 运行
./install.sh
```

## 前置条件

- bash 3.0+
- [python3](https://www.python.org/)（解析 tools.json）
- [curl](https://curl.se/)（部分安装方式需要）
- [npm](https://nodejs.org/)（选择 npm 方式时需要）
- 代理软件（可选，端口默认 `7890`）

## 工作流程

```
1. 检测系统 + 显示系统信息
       ↓
2. 询问是否配置代理 (默认 / 自定义 / 直连)
       ↓
3. 询问是否配置 ELECTRON_MIRROR (加速 Electron 下载)
       ↓
4. 选择要安装的工具
   ├─ 工具列表从 tools.json 读取
   ├─ 已安装的工具显示版本号
   └─ 无"全部安装"选项，每次安装一个
       ↓
5. 选择安装方式
   ├─ 仅展示当前系统的安装方式
   ├─ 选项直接显示安装命令
   └─ 标签: [推荐] / [已废弃] / ↳ 备注
       ↓
6. 执行安装 → 验证版本
       ↓
7. 清除代理和 ELECTRON_MIRROR 环境变量
```

## 输出示例

```
========================================
   AI 编程助手安装
========================================

[*] 系统信息 macOS / arm64
[*] 是否配置代理？ (默认: http://127.0.0.1:7890)
    y) 使用代理
    n) 不使用代理，直连
    c) 自定义代理地址
    请选择 [y/n/c]: n

[*] 是否配置 ELECTRON_MIRROR？ (https://npmmirror.com/mirrors/electron)
    y) 配置
    n) 不配置
    请选择 [y/n]: y
[✓] 已设置 ELECTRON_MIRROR: https://npmmirror.com/mirrors/electron

[*] 请选择要安装的工具:
    1) Claude Code 2.1.177
    2) Codex 0.139.0
    3) OpenCode 1.17.4
    4) Hermes 未安装
    q) 退出
    请选择: 1

[*] 请选择 Claude Code 的安装方式:
    1) curl -fsSL https://claude.ai/install.sh | bash  [推荐]
    2) brew install --cask claude-code
       ↳ 更新较慢
    3) npm install -g @anthropic-ai/claude-code  [已废弃]
    请选择: 1

----------------------------------------
[→] 安装 Claude Code
    curl -fsSL https://claude.ai/install.sh | bash

[✓] Claude Code 安装成功: 2.1.177
```

## 配置文件 (tools.json)

工具列表和安装命令都在 `tools.json` 中，结构如下：

```json
{
  "claude_code": {
    "name": "Claude Code",
    "cmd": "claude",
    "installation": {
      "macos": [
        { "cmd": "curl ...", "recommended": true },
        { "cmd": "brew ...", "note": "更新较慢" },
        { "cmd": "npm ...", "deprecated": true }
      ],
      "linux": [ ... ],
      "windows": [ ... ]
    }
  }
}
```

**字段说明：**

| 字段 | 说明 |
|------|------|
| `name` | 工具显示名称 |
| `cmd` | 命令名（用于版本检查） |
| `installation` | 按系统分组的安装方式列表 |
| `cmd`（方法内） | 实际执行的安装命令 |
| `recommended` | 标记为 `[推荐]` |
| `deprecated` | 标记为 `[已废弃]` |
| `note` | 备注信息，换行显示 |

## 文件结构

```
install_ai_tools/
├── install.sh    # 主脚本：检测系统、读取配置、交互式安装
├── tools.json    # 工具和安装命令配置
└── README.md     # 本文档
```

## 注意事项

- 脚本运行结束后会自动清除代理环境变量
- 每次只安装一个工具，不支持批量安装
- 已安装的工具会显示版本号，选择后询问是否重新安装
- 添加新工具或安装方式只需修改 `tools.json`，无需改脚本
