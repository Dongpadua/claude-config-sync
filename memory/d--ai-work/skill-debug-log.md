---
name: skill-debug-log
description: 技能/功能使用过程中遇到的问题及解决方案索引。使用任何技能前先查此记录。
metadata: 
  node_type: memory
  type: reference
  originSessionId: 97b1a692-ccce-4ddb-b101-9d72d6dab43e
---

# 技能问题日志

使用任何技能或功能前，先读本文档查看已知问题。

## 记录格式

```
### YYYY-MM-DD | 技能名 | 问题简述

**现象：** 一句话描述
**原因：** 根因
**解决：** 怎么做
**下次注意：** 一句话
```

---

### 2026-06-15 | douyin-ocr / mrcarlsama-social-transcriber | 双通道合并时人工整理出错

**现象：** 音频+OCR 校对后，最终输出有两处错误：① "由衷"误写成"郑重" ② 漏掉"是"字
**原因：** OCR 识别"由裹"（衷的形近字），人工脑补推断为"郑重"而非"由衷"；手动打字时凭记忆漏字
**解决：** 封装为 douyin-ocr skill，规则：不做润色、只做校对、直接拼接不手动输入、歧义标注让用户判断
**下次注意：** 能复制就不要打字；不要替作者选词；OCR 碎片不等于完整句

### 2026-06-15 | mrcarlsama-social-transcriber | Bash 运行 GBK 编码报错

**现象：** `uv run --script run_one.py` 时 subprocess 报 `UnicodeDecodeError: 'gbk' codec can't decode byte 0x80`
**原因：** Windows Git Bash subprocess 默认使用 GBK，yt-dlp 输出含非 GBK 字符
**解决：** 用 PowerShell 运行，或在 Bash 前 `export PYTHONUTF8=1 PYTHONIOENCODING=utf-8`
**下次注意：** Windows 上优先用 PowerShell 跑 Python 脚本，避免 Bash 编码问题

### 2026-06-15 | mrcarlsama-social-transcriber | faster-whisper 不在全局 Python 环境

**现象：** 直接 `python transcribe.py` 报 `ModuleNotFoundError: No module named 'faster_whisper'`
**原因：** 依赖通过 `uv` 安装在隔离环境，全局 Python 没有
**解决：** 用 `uv run --script` 或 `uv run --with faster-whisper --with av python script.py`
**下次注意：** skill 脚本必须通过 uv 调用，不要直接 python

### 2026-06-15 | douyin-ocr | EasyOCR 视频扫描极慢

**现象：** 44s 视频 OCR 耗时 66s+，每帧 3-5 秒
**原因：** EasyOCR 纯 CPU 跑 CRAFT 检测模型 + PyTorch 开销大
**解决：** 替换为 RapidOCR (ONNX Runtime) + 帧差跳帧（阈值 12），从 66s 降到 ~12s（6x 提速）
**下次注意：** 视频 OCR 用 RapidOCR 不用 EasyOCR；猫 meme 类字幕在底部 40%，知识类标题在顶部 30%

### 2026-06-15 | douyin-ocr | OCR 扫错区域导致结果为空

**现象：** 猫 meme 视频 OCR 只扫到 3 帧有文本，其余全是空白
**原因：** 只扫描了顶部 35%，猫 meme 字幕在底部
**解决：** 改为双区域扫描：顶部 30%（标题/标签）+ 底部 40%（字幕）
**下次注意：** 先判断视频类型再决定扫描区域；猫 meme/剧情类 = 底部字幕，知识/Vlog 类 = 全屏文字

### 2026-06-15 | douyin-ocr | 三次人工润色错误（由衷→郑重 / 漏"是"字 / 加"任何"）

**现象：** 
1. "由衷" 被脑补为 "郑重"
2. "一定是需要" 漏了 "是"
3. "喜欢你没有理由" 被加字为 "喜欢你没有任何理由"

**原因：** 三次都出在同一个环节——音频+OCR 校对完成后，我在"整理输出"时不自觉地润色。觉得不够顺就加词、凭记忆打字漏字、OCR 模糊时自己猜词。这不是技术问题，是行为问题。

**解决：** douyin-ocr skill 已写入规则：① 不做润色改写 ② 能直接复制的不要手动输入 ③ OCR 模糊标注让用户判断。但规则写了还是会犯——说明需要更强制的手段。

**下次注意：** 校对完成后，逐字对照音频/OCR 原文再读一遍，确认没有多词/少词/改词。输出前默念：你只是转写，不是编辑。
**规则变更 (2026-06-15)：** douyin-ocr 从"音频为主 OCR 为辅"改为"**OCR 为主，音频兜底**"。OCR 画面文字是权威来源，识别到什么输出什么，不加字不漏字不改字。音频只在 OCR 完全没扫到时才用。

### 2026-06-16 | cc-connect | 微信回复数量递增（2→4→5→6→7→8条）的反馈循环

**现象：** 微信上发一条消息，收到的回复越来越多（从 2 条涨到 8 条），每次"重启"后数量反而增加。

**原因：** `kill` 命令在 Windows Bash 上杀不死 Go 编译的 cc-connect.exe 进程。每次"重启"实际上是启动了新进程，旧进程还在跑。高峰期同时有 8 个 cc-connect 实例 + 9 个 Claude 实例，全部在轮询同一个 ilink Bot——用户发一条消息，8 个实例各自处理并回复，产生 8 倍消息。

**解决：** 用 PowerShell `Get-Process cc-connect` 查所有残留进程 → `Stop-Process` 逐个强杀 → 清锁文件和 session → 确认只有 1 个进程后重启。

**下次注意：** 
1. Windows 上杀进程必须用 `Stop-Process -Name cc-connect -Force`，不能用 bash `kill`
2. 重启前必须 `Get-Process cc-connect` 确认旧实例已全部退出
3. 永远不要让 `cc-connect` 进程数 > 1

**诊断教训 (2026-06-16)：** 故障排查必须从底层往上查，不能跳过基础检查直接猜配置/代码问题。本次 8 进程事故浪费了 6 轮猜测（改 allow_from、改 clean_reply、加 project.display、删 session、回退配置、升 beta.5），其实第一轮就该 `Get-Process cc-connect` 发现多实例。排查顺序：进程状态 → 网络连通 → 配置变更 → 代码逻辑。
