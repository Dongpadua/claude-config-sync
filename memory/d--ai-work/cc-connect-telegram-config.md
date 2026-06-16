---
name: cc-connect-telegram-config
description: cc-connect 接入 Telegram 的完整配置（DeepSeek V4 Pro + 关闭思考显示 + 清理页脚）
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8c221e34-f4ae-4a5e-ad8a-2b818f054e12
---

# cc-connect Telegram 接入配置

## 版本要求

cc-connect **v1.3.3-beta.4+** 才支持 `show_context_indicator` 和 `show_workdir_indicator`。

```bash
cc-connect update --pre  # 升级到 beta 版本
```

## 最终配置 `~/.cc-connect/config.toml`

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
api_key = "sk-..."
base_url = "https://api.deepseek.com/anthropic"
model = "deepseek-v4-pro"
thinking = "disabled"

[[projects.platforms]]
type = "telegram"

[projects.platforms.options]
token = "YOUR_TELEGRAM_BOT_TOKEN"
```

## 关键设置说明

| 设置 | 作用 |
|------|------|
| `thinking = "disabled"` (provider) | 禁用 DeepSeek 模型的 💭 思考输出 |
| `thinking_messages = false` | 隐藏 cc-connect 的思考状态消息 |
| `tool_messages = false` | 隐藏工具调用进度 |
| `show_context_indicator = false` | 去除 `[ctx: ~0%]` |
| `show_workdir_indicator = false` | 去除 `…/D:/ai work` 路径 |
| `reply_footer = false` | 去除整个页脚 |

## 教训

- `[display]` 全局设置仅在 v1.3.3-beta.4+ 对 claudecode agent 生效
- v1.3.2 版本的 display 设置对 claudecode 无效（已知 bug）
- provider 中的 `thinking = "disabled"` 需要在 cc-connect 中显式声明，不能依赖 Claude Code 的 settings.json 中的 env vars

## 微信 (ilink) 接入

```bash
cc-connect weixin setup --project ai-work
```

扫码绑定后，配置自动写入 `[[projects.platforms]]`，类型为 `"weixin"`。

```toml
[[projects.platforms]]
type = "weixin"

[projects.platforms.options]
token = "auto-filled"
base_url = "https://ilinkai.weixin.qq.com"
account_id = "auto-filled"
```

⚠️ 绑定后需重启 cc-connect，然后在微信里给机器人发一条消息完成 `context_token` 关联。
