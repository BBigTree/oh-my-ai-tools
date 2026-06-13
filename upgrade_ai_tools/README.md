# AI 编程助手一键升级脚本

自动检测并升级本机安装的 AI 编程 CLI 工具。

## 支持的工具

| 工具 | 升级命令 | 版本查询来源 |
|------|---------|-------------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `claude update` | npm: `@anthropic-ai/claude-code` |
| [Codex](https://github.com/openai/codex) | `codex update` | npm: `@openai/codex` |
| [OpenCode](https://github.com/sst/opencode) | `opencode upgrade` | GitHub Releases API |
| Hermes | `npm install -g hermes-cli@latest` | npm: `hermes-cli` |

> 未安装的工具会自动跳过，不会报错。

## 前置条件

- macOS / Linux
- [npm](https://nodejs.org/)（用于查询 npm registry 版本号）
- [curl](https://curl.se/)（用于查询 GitHub API）
- Clash for Windows 或其他代理软件（可选，端口默认 `7890`）

## 快速开始

```bash
# 赋予执行权限（首次）
chmod +x upgrade_ai_tools.sh

# 运行
./upgrade_ai_tools.sh
```

## 工作流程

```
1. 检测代理 → 设置环境变量（http_proxy / https_proxy / ALL_PROXY）
       ↓
2. 查询远程最新版本
   ├─ Claude Code  → npm registry
   ├─ Codex        → npm registry
   ├─ OpenCode     → GitHub API
   └─ Hermes       → 检查是否安装
       ↓
3. 对比当前版本 vs 最新版本（语义化版本比较）
       ↓
   ┌─ 版本相同 → ✅ 已是最新，跳过
   ├─ 版本不同 → ⬆️ 执行升级
   └─ 查询失败 → ⚠️ 跳过，避免盲目操作
       ↓
4. 清除代理环境变量 → 输出汇总报告
```

## 输出示例

```
========================================
   AI 编程助手一键升级
========================================

[✓] 代理可用: http://127.0.0.1:7890
[*] 已设置代理环境变量

[*] 正在查询最新版本...

----------------------------------------
[✓] Claude Code — 已是最新版本 (2.1.177)
----------------------------------------
[↑] Codex — 需要升级: 0.135.0 -> 0.139.0
[✓] Codex 升级完成 (0.135.0 -> 0.139.0)
----------------------------------------
[↑] OpenCode — 需要升级: 1.17.3 -> v1.17.4
[✓] OpenCode 升级完成 (1.17.3 -> 1.17.4)
----------------------------------------
[⊘] Hermes — 未安装，跳过

[*] 已清除代理环境变量

========================================
   升级汇总
========================================
   升级成功: 2
   已是最新: 1
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

代理不可用时脚本会自动回退到直连模式，不会中断执行。

## 目录结构

```
.
├── upgrade_ai_tools.sh   # 升级脚本
└── README.md             # 说明文档
```

## 注意事项

- 脚本运行结束后会自动清除本次设置的代理环境变量，不影响系统原有配置
- 升级操作需要网络能访问 npm registry 和 GitHub API
- 各工具的独立二进制文件升级由其自身 `update`/`upgrade` 命令完成，脚本不直接替换文件
