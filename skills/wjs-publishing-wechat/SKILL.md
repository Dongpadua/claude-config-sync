---
name: wjs-publishing-wechat
description: 微信公众号发布工具——生成题图、解释图，上传草稿到微信后台。由 wjs-mining-articles 调用，也可独立使用。触发词："发公众号"、"上传草稿"、"publish wechat"。
---

# wjs-publishing-wechat — 微信公众号发布

## 前置条件

需要微信公众号 AppID 和 AppSecret。在公众号后台 → 设置与开发 → 基本配置 获取。

配置方式：创建 `~/.wechat-mp-config.json`：
```json
{
  "appid": "wx0000000000000000",
  "secret": "your_secret_here",
  "author": "作者名"
}
```

## 脚本

| 脚本 | 作用 | 输入 |
|------|------|------|
| `scripts/pangu.py` | 中英文间补空格（盘古之白） | article.md |
| `scripts/gen-cover-ai.sh` | 生成公众号题图 900×383 | meta.json + article.md |
| `scripts/gen-illustration.sh` | 生成文章插图 | meta.json + article.md |
| `scripts/upload-draft.sh` | 上传草稿到微信后台 | article.md + meta.json |

## 字数与格式硬约束

- 默认 800–1000 字，超 1200 砍掉
- 红色加粗 `**...**` 2–4 处（点睛句/核心观点）
- 不加 AI 连接词（首先/其次/综上所述/值得注意的是）
- 不加 emoji
- 中英文之间要有空格

## 工作流

```
article.md + meta.json
  ↓
pangu.py          ← 盘古之白
  ↓
gen-cover-ai.sh   ← 题图 cover.png
  ↓
gen-illustration.sh ← 插图 illustration.png
  ↓
upload-draft.sh   ← 微信后台草稿
  ↓
✅ 草稿就绪，用户在后台手动群发
```
