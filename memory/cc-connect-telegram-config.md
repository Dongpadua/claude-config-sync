---
name: cc-connect-telegram-config
description: cc-connect 接入 Telegram 完整配置
metadata: 
  node_type: memory
  type: reference
  originSessionId: 97b1a692-ccce-4ddb-b101-9d72d6dab43e
---

# cc-connect Telegram 配置

## 关键设置 `~/.cc-connect/config.toml`

```toml
[display]
mode = "quiet"
thinking_messages = false       # 隐藏思考
tool_messages = false           # 隐藏工具
show_context_indicator = false  # 去 [ctx:~0%]
show_workdir_indicator = false  # 去路径
reply_footer = false            # 去页脚

[projects.agent.providers]
thinking = "disabled"           # 禁 DeepSeek 💭 输出
```

**教训：**
- v1.3.3-beta.4+ display 才对 claudecode 生效
- `thinking="disabled"` 须在 provider 声明，不依赖 settings.json
- 微信: `cc-connect weixin setup --project ai-work` → 扫码 → 重启 → 发消息
