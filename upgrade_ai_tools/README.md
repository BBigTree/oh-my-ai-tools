# AI 编程助手一键升级脚本

检测并升级本机已安装的 AI 编程 CLI 工具。

## 支持的工具

| 工具 | 升级命令 | GitHub 来源 | npm 回退 |
|------|---------|------------|---------|
| [Claude Code](https://github.com/anthropics/claude-code) | `claude update` | `anthropics/claude-code` | `@anthropic-ai/claude-code` |
| [Codex](https://github.com/openai/codex) | `codex update` | `openai/codex` | `@openai/codex` |
| [OpenCode](https://github.com/anomalyco/opencode) | `opencode upgrade` | `anomalyco/opencode` | `opencode-ai` |
| [Hermes](https://github.com/NousResearch/hermes-agent) | `hermes update` | `NousResearch/hermes-agent` | `hermes-agent` |

> 未安装的工具会自动跳过，不会报错。

## 前置条件

- macOS / Linux
- [curl](https://curl.se/) + [python3](https://www.python.org/)（查询 GitHub 版本）
- [npm](https://nodejs.org/)（GitHub 不可用时回退查询版本，可选）
- 代理软件（可选，端口默认 `7890`）

## 快速开始

```bash
# 赋予执行权限（首次）
chmod +x upgrade_ai_tools.sh

# 运行
./upgrade_ai_tools.sh
```

## 工作流程

```
1. 询问是否配置代理（默认 / 自定义 / 直连）
       ↓
2. 显示待检查工具概览（工具 / 当前版本）
       ↓
3. 逐个检查已安装工具：
   ├─ 查询最新版本：GitHub 优先，失败回退 npm
   ├─ 对比当前版本 vs 最新版本（语义化版本比较）
   ├─ 版本相同 → ✅ 已是最新
   ├─ 版本不同 → ⬆️ 执行升级
   └─ 未安装   → 跳过
       ↓
4. 清除代理环境变量 → 输出汇总报告
```

## 输出示例

```
========================================
   AI 编程助手一键升级
========================================

[*] 是否配置代理？ (默认: http://127.0.0.1:7890)
    y) 使用代理
    n) 不使用代理，直连
    c) 自定义代理地址
    请选择 [y/n/c]: y
[✓] 代理可用: http://127.0.0.1:7890
[✓] 已设置代理环境变量

[*] 待检查工具 (工具 / 当前版本)

    ──────────────────────────────────
    Claude Code     2.1.177
    Codex           0.139.0
    OpenCode        1.17.4
    Hermes          未安装

----------------------------------------
[→] 正在检查 Claude Code
    GitHub: github.com/anthropics/claude-code
    [!] GitHub 查询失败，切换 npm 查询最新版本
    npm: @anthropic-ai/claude-code
[✓] Claude Code — 已是最新版本 (2.1.177)
----------------------------------------
[→] 正在检查 Codex
    GitHub: github.com/openai/codex
[✓] Codex — 已是最新版本 (0.139.0)
----------------------------------------
[⊘] Hermes — 未安装，跳过

[*] 已清除代理环境变量

========================================
   升级汇总
========================================
   升级成功: 0
   已是最新: 3
   未安装:   1
========================================
```

## 代理配置

默认使用 Clash for Windows 的 mixed-port：

| 配置项 | 值 |
|-------|---|
| HTTP 代理 | `http://127.0.0.1:7890` |
| SOCKS5 代理 | `socks5://127.0.0.1:7890` |

如需修改，编辑脚本顶部的变量：

```bash
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
```

代理不可用时会询问是否跳过，选择直连或终止。

## 版本查询策略

```
GitHub API (releases/latest)
    ↓ 成功 → 使用 GitHub 版本
    ↓ 失败
npm registry (回退)
    ↓ 成功 → 使用 npm 版本
    ↓ 失败
跳过该工具（无法获取最新版本）
```

> GitHub 匿名访问限制 60 次/小时，超限后自动回退 npm 查询。

## 目录结构

```
.
├── upgrade_ai_tools.sh   # 升级脚本
└── README.md             # 说明文档
```

## 注意事项

- 脚本运行结束后会自动清除本次设置的代理环境变量，不影响系统原有配置
- 仅升级已安装的工具，不会安装新工具
- 各工具升级由其自身 `update` / `upgrade` 命令完成，脚本不直接替换文件
