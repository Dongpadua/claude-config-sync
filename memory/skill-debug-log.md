---
name: skill-debug-log
description: 技能/功能已知问题索引，用前先查
metadata: 
  node_type: memory
  type: reference
  originSessionId: 97b1a692-ccce-4ddb-b101-9d72d6dab43e
---

# 技能问题日志

格式：`### 日期 | 技能 | 问题 → 原因 → 解决`

---

### 2026-06-15 | douyin-ocr | 校对后人工改错字（由衷→郑重/漏"是"/加"任何"）
→ 手动输入时脑补润色 → 规则：不润色不改写，OCR为主音频兜底，歧义标注

### 2026-06-15 | mrcarlsama-social-transcriber | GBK编码报错
→ Win Bash subprocess 默认 GBK → 用 PowerShell 或 `export PYTHONUTF8=1`

### 2026-06-15 | mrcarlsama-social-transcriber | faster-whisper 找不到
→ uv 隔离安装 → 用 `uv run --script` 不直接 python

### 2026-06-15 | douyin-ocr | EasyOCR 66s太慢
→ CPU跑CRAFT → 换 RapidOCR + 帧差跳帧 → 12s (6x)

### 2026-06-15 | douyin-ocr | 猫meme OCR空白
→ 只扫顶部35% → 改双区域：顶部30%+底部40%

### 2026-06-16 | cc-connect | 微信回复8条
→ bash kill 杀不死Go进程 → 8实例堆积 → `Stop-Process -Force` 清光重启
**教训：排查从底层往上 → 进程状态→网络→配置→代码。不跳步。**
