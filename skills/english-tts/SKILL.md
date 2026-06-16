---
name: english-tts
description: 英文文本转语音。将任意英文文本通过 Microsoft Edge TTS（免费神经网络语音）转为 MP3 音频文件。支持美式/英式/澳式男声女声共 9 种常用音色，可调语速。适用场景：听译文、制作配音、语言学习、朗读文章。触发词："朗读"、"转语音"、"TTS"、"text to speech"、"念出来"、"读英文"、"生成音频"。
---

# English Text-to-Speech (Edge TTS)

使用 Microsoft Edge 免费神经网络语音，将英文文本转为高质量 MP3 音频。

## 特点

- **免费**：无需 API Key，无用量限制
- **高质量**：Azure 神经网络语音，接近真人
- **多音色**：9 种常用英文声音（美式/英式/澳式 × 男/女）
- **可调速**：0.5x ~ 2.0x
- **输出 MP3**：通用格式，任何设备可播放

## 执行

```bash
python "$HOME/.claude/skills/english-tts/scripts/tts.py" \
  --text "<英文文本>" \
  --voice "<音色>" \
  --rate "<语速>" \
  --output "<输出路径.mp3>"
```

### 参数

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `--text` | 是 | - | 要转换的英文文本 |
| `--voice` | 否 | `en-US-JennyNeural` | 音色（见下方列表） |
| `--rate` | 否 | `+0%` | 语速：`-30%`(慢) / `+0%`(正常) / `+20%`(快) |
| `--output` | 否 | 桌面 `tts_output.mp3` | 输出路径 |

### 常用音色

| Voice ID | 性别 | 口音 | 风格 |
|----------|------|------|------|
| `en-US-JennyNeural` | 女 | 美式 | 友好、多功能（**默认**） |
| `en-US-AriaNeural` | 女 | 美式 | 富有表现力、戏剧感 |
| `en-US-GuyNeural` | 男 | 美式 | 温暖、讲故事 |
| `en-US-DavisNeural` | 男 | 美式 | 专业、权威 |
| `en-US-AnaNeural` | 女 | 美式 | 清晰、童声（适合有声书） |
| `en-GB-SoniaNeural` | 女 | 英式 | 温暖、专业 |
| `en-GB-RyanNeural` | 男 | 英式 | 正式、深沉 |
| `en-AU-NatashaNeural` | 女 | 澳式 | 友好 |
| `en-AU-WilliamNeural` | 男 | 澳式 | 随和 |

### 示例

```bash
# 默认美式女声
python tts.py --text "I always believed that farewells were meant to be marked by grand ceremonies."

# 英式男声，稍慢
python tts.py --voice en-GB-RyanNeural --rate -20% --text "The paths we leave behind may never cross again."

# 指定输出路径
python tts.py --voice en-US-GuyNeural --text "You will always be my one and only." --output ~/Desktop/love.mp3
```

## 长文本处理

超过 ~500 字的文本会自动分段，段落间加短暂停顿。大段文本也可以直接传入。

## 注意事项

- 首次使用需联网（edge-tts 会连接微软服务），不消耗 API 额度
- 仅支持英文 TTS，中文请用其他工具
- Windows/macOS/Linux 全平台可用
