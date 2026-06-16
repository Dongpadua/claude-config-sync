---
name: gemini-poster
description: Gemini 生图全流程：打开→提示词→下载完整尺寸→清晰化→加水印。触发："生成海报""Gemini生图""做一张图"。
---

# Gemini Poster

## 前置
1. Chrome 调试模式（端口9222）：运行 `~/.claude-config-sync/scripts/gemini.ps1`
2. Gemini 已登录

## 流程
```
gemini.ps1 → Chrome 调试 → agent-browser connect 9222 → 输提示词 → 等生成
→ 点"下载完整尺寸的图片" → 提取 → 清晰化 → 加水印 → 保存
```

## 一键使用
```
帮我生成一张端午节海报，水墨风格
```
自动走全流程。

## 输出（默认 `桌面/海报/`）
| 文件 | 说明 |
|------|------|
| `gemini_orig.png` | 原始 |
| `gemini_sharp.png` | 清晰化 |
| `gemini_final.png` | 清晰化+水印 |

## 配置
- 水印：`桌面/公众号/顺新文旅.png`，宽度24%，左上角(40,40)
- 脚本：`scripts/gemini_download.py`（一条龙：CDP下载→清晰化→加水印）
