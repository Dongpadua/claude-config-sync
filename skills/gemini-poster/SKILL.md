---
name: gemini-poster
description: Gemini 生图全流程自动化——打开 Gemini、输入提示词、下载完整尺寸图片、清晰化、加水印。触发词："生成海报"、"Gemini生图"、"做一张图"、"gemini poster"。
---

# Gemini Poster — AI 生图全流程

## 前置条件

1. Chrome 需以调试模式运行（端口 9222）
2. 运行 `~/.claude-config-sync/scripts/gemini.ps1` 一键启动
3. Gemini 需已登录 Google 账号

## 完整流程

```
gemini.ps1 → Chrome 调试模式
    ↓
agent-browser connect 9222
    ↓
输入提示词 → Gemini 生成图片
    ↓
点击"下载完整尺寸的图片"
    ↓
从 Downloads 提取 → 清晰化 → 加水印 → 保存
```

## 使用方式

### 一键生成
```
帮我生成一张端午节海报，水墨风格，含龙舟粽子
```
Claude 自动：开 Chrome → 输提示词 → 等生成 → 下载 → 处理

### 只处理已有图片
```
把刚才 Gemini 生成的图清晰化加水印
```
跳过生成，直接从当前页面下载并处理。

## 脚本

| 脚本 | 用途 |
|------|------|
| `scripts/gemini_download.py` | 连接 CDP → 点击下载按钮 → 提取文件 |
| `scripts/enhance.py` | 清晰化 + 对比度增强 |
| `scripts/watermark.py` | 添加水印 |

## 输出

所有文件保存到指定目录（默认 `桌面/海报/`）：

| 文件 | 说明 |
|------|------|
| `gemini_orig.png` | 原始完整尺寸（1536×2752） |
| `gemini_sharp.png` | 清晰化处理后 |
| `gemini_final.png` | 清晰化 + 水印 |

## 配置

水印文件：`C:\Users\Administrator\Desktop\公众号\顺新文旅.png`
水印大小：图片宽度的 24%
水印位置：左上角 (40, 40)

修改方式：编辑 `scripts/enhance.py` 中的参数
