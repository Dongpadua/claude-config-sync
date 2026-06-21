---
name: cc-connect-dual-platform
description: 双电脑双平台接入架构 — 当前PC用微信ilink，另一台PC用Telegram
metadata:
  node_type: memory
  type: project
  originSessionId: 96f7c508-a646-4c33-8dd0-96aa7ad02078
---

# cc-connect 双平台接入架构

## 架构概览

```
┌─────────────────────────────┐     ┌─────────────────────────────┐
│       当前 PC (新电脑)        │     │       另一台 PC (旧电脑)      │
│                              │     │                              │
│  cc-connect v1.3.4           │     │  cc-connect v1.3.4           │
│  平台: 微信 (ilink)           │     │  平台: Telegram               │
│                              │     │                              │
│  WeChat ──▶ ilink Bot ──▶   │     │  Telegram ──▶ Bot ──▶       │
│  Claude Code (DeepSeek V4)  │     │  Claude Code (DeepSeek V4)  │
│                              │     │                              │
│  工作目录: d:/ai work         │     │  工作目录: d:/ai work         │
└─────────────────────────────┘     └─────────────────────────────┘

         ⚠️ 两台不能同时跑 cc-connect（同一个 ilink Bot 会冲突）
         ✅ 不同平台（微信 vs Telegram）可以同时运行
```

## 当前 PC — 微信 (ilink)

### 安装状态

| 项目 | 值 |
|------|----|
| cc-connect 版本 | v1.3.4 |
| 安装路径 | npm global (`C:\Users\30303\AppData\Roaming\npm\`) |
| 配置文件 | `~/.cc-connect/config.toml` |
| 项目名称 | ai-work |
| 平台 | weixin (ilink) |
| ilink Bot ID | `805686161b6b@im.bot` |
| 进程 | 单实例，PID 文件锁 |
| 工作目录 | `d:/ai work` |
| 模型 | deepseek-v4-pro (api.deepseek.com/anthropic) |

### 配置文件 (~/.cc-connect/config.toml)

```toml
language = "zh"

[display]
mode = "quiet"
thinking_messages = false
tool_messages = false
show_context_indicator = false
reply_footer = false
show_workdir_indicator = false

[[projects]]
name = "ai-work"

[projects.agent]
type = "claudecode"

provider_refs = ["deepseek"]

[projects.agent.options]
work_dir = "d:/ai work"
mode = "default"

[[projects.agent.providers]]
name = "deepseek"
api_key = "sk-a29ac74fc47f4f3795fc2c6ea233278c"
base_url = "https://api.deepseek.com/anthropic"
model = "deepseek-v4-pro"
thinking = "disabled"

[[projects.platforms]]
type = "weixin"

[projects.platforms.options]
token = "805686161b6b@im.bot:060000bb5b070628b9def62ed341d06c30c1b6"
base_url = "https://ilinkai.weixin.qq.com"
account_id = "805686161b6b@im.bot"
```

### 常用命令

```bash
# 启动
cc-connect run --project ai-work

# 查看状态
Get-Process cc-connect

# 重新绑定微信（换号/过期）
cc-connect weixin setup --project ai-work

# 停止
Stop-Process -Name cc-connect -Force
```

---

## 另一台 PC — Telegram

### 安装 (到那台电脑上执行)

```bash
npm install -g cc-connect@latest
mkdir -p "$HOME/.cc-connect"
mkdir -p "d:/ai work"
```

### 配置文件 (~/.cc-connect/config.toml)

```toml
language = "zh"

[display]
mode = "quiet"
thinking_messages = false
tool_messages = false
show_context_indicator = false
reply_footer = false
show_workdir_indicator = false

[[projects]]
name = "ai-work"

[projects.agent]
type = "claudecode"

provider_refs = ["deepseek"]

[projects.agent.options]
work_dir = "d:/ai work"
mode = "default"

[[projects.agent.providers]]
name = "deepseek"
api_key = "sk-a29ac74fc47f4f3795fc2c6ea233278c"
base_url = "https://api.deepseek.com/anthropic"
model = "deepseek-v4-pro"
thinking = "disabled"

[[projects.platforms]]
type = "telegram"

[projects.platforms.options]
token = "YOUR_TELEGRAM_BOT_TOKEN"
```

### 获取 Telegram Bot Token

1. 在 Telegram 里找 [@BotFather](https://t.me/BotFather)
2. 发送 `/newbot` → 输入名称 → 拿到 token
3. 填入上面配置的 `YOUR_TELEGRAM_BOT_TOKEN` 位置

### 常用命令

```bash
# 启动
cc-connect run --project ai-work

# 停止
Stop-Process -Name cc-connect -Force
```

---

## 跨平台规则

| 规则 | 说明 |
|------|------|
| **不同平台可同时运行** | 微信 + Telegram 各跑各的，不冲突 |
| **同平台禁止双开** | 两台电脑不能同时登录同一个 ilink Bot 或同一个 Telegram Bot |
| **切换电脑时** | 先停旧电脑的 cc-connect，再启新电脑的 |
| **模型配置一致** | 两台都用 DeepSeek V4 Pro + thinking=disabled |
| **显示配置一致** | 都用 quiet 模式，隐藏思考/工具/页脚/路径 |

## 参考

- [[cc-connect-telegram-config]] — Telegram 详细配置参考 (旧文档)
- [[skill-debug-log]] — cc-connect 多进程故障排查教训
- [[no-confirmation-ever]] — 零交互执行铁律
