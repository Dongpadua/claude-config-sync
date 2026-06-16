---
name: cuimao-translator-zh2en
description: 中文→英文文学翻译。遵循信达雅原则，将中文文章、诗歌、散文、书籍翻译成自然流畅的英文，保留原文风格与情感，消除中式英语痕迹。适用场景：中译英、Chinese to English translation、文学翻译、诗歌翻译、散文翻译、出版级翻译。触发词："翻译成英文"、"中译英"、"translate to English"、"翻成英语"、"英译"、"literary translation"。
---

# Literary Translator (Chinese → English)

Three-mode translation skill for turning Chinese text into natural, idiomatic English. The core commitment is **sentence-by-sentence fidelity** — every sentence in the original must exist in the translation, with no meaning added or lost — while reading as if written by a native English author.

## Modes

| Mode | Trigger | Steps | Best for |
|------|---------|-------|----------|
| **Quick** | "快翻", "quick" | Read → Translate | Quick understanding, single paragraph |
| **Normal** | default, "翻译", "中译英" | Analyze → Translate | Most content, articles, prose |
| **Refined** | "精翻", "refined", "精细翻译" | Analyze → Draft → Review → Revise → Polish | Publication, poetry, literary prose |

## Style Presets

| Style | When to use | Characteristics |
|-------|-------------|-----------------|
| `literal` | Technical, legal, precision-critical | Closest to Chinese structure, minimal reordering |
| `literary` | Essays, prose, 散文, social media poetry | Natural English rhythm, vivid but not flowery |
| `poetic` | 诗词, classical verse, rhythmic prose | Meter awareness, compressed imagery, line breaks |
| `conversational` | Dialogue, social media, casual | Contractions, natural pauses, spoken rhythm |
| `academic` | Scholarly papers, formal analysis | Formal register, precise terminology |

Default: **literary** for most Chinese prose. `literal` only for technical/legal.

## Core Philosophy (信达雅)

### 信 Faithfulness
- Every Chinese sentence → one English sentence. No skipping, no summarizing, no embellishing
- Facts, numbers, names match exactly
- Preserve emotional temperature: understated Chinese → understated English

### 达 Fluency — The craft
- The English must read like native writing, NOT like translation
- **Chinese parataxis → English hypotaxis**: Add logical connectors where English needs them; don't over-connect where Chinese leaves gaps
- **Restore subjects**: Chinese drops them; English usually needs them
- **Infer tenses**: Chinese uses aspect markers (了/过/着), not tense. Apply consistent English tense from context
- **Break run-on sentences**: Chinese comma-splices independent clauses freely. English needs periods or semicolons
- **No comma splicing**: Chinese comma ≠ English comma. Break into proper sentences

### 雅 Cultural Adaptation — The art
- **成语 → English equivalent**, not literal: "画蛇添足" → "gild the lily", not "draw legs on a snake"
- **Cultural images → English-native images**: "山水" in farewell context → "the distance between us" or "paths we leave behind", not "mountains and rivers"
- **Preserve register**: 书面语→formal, 口语→casual, 网络用语→internet-native English
- **留白 respected**: Don't over-explain what the Chinese leaves implied

## Anti-Chinglish Checklist (6 Red Flags)

1. **Dangling topics**: "这个问题，我们已经讨论过了" → "We've discussed this" (not "This issue, we've discussed it")
2. **Missing articles**: Every English noun phrase needs a/the/∅ determined
3. **Tense drift**: Chinese has no tense — pick a timeline and stick to it
4. **Literal 成语**: "对牛弹琴" → "casting pearls before swine" (not "playing music to a cow")
5. **Comma splicing**: One Chinese sentence ≠ one English sentence. Break at logical boundaries
6. **Redundant pairs**: "清清楚楚" → "clearly" (not "clearly and distinctly")

## Output Format

Short content → English text directly. No headers unless asked.

Long content:
```
# [Title] — English Translation

## Notes
- Original: [Title] by [Author]
- Style: [preset], [mode]

---

## Chapter N

English text...

---

*— End of Chapter N —*
```

## Workflow

### Quick mode
Read → translate → output.

### Normal mode (default)
1. **Quick scan**: genre, register, key terms, tricky spots (成语/典故), tense baseline
2. **Translate** paragraph by paragraph
3. **Self-check**: all sentences present? reads native? articles/tenses correct? 成语 adapted?

### Refined mode
1. Analyze → 2. Draft → 3. Review (accuracy + Chinglish + cultural gaps + tone) → 4. Revise → 5. Polish (rhythm, word choice, consistency)

## Example

Input:
> 我一直以为所谓的告别，一定是需要一场盛大的仪式。
> 所以我一直在等，等一个温暖的拥抱，等一声由衷的再见。
> 等到最后我才发现，人生中大部分的告别都是悄无声息的。
> 来日不一定方长，山水也未必重逢。

Output (literary style):
> I always believed that farewells were meant to be marked by grand ceremonies.
> So I waited — for a warm embrace, for a goodbye spoken from the heart.
> Only later did I realize that most farewells in life happen in silence.
> The days ahead may not be endless, and the paths we leave behind may never cross again.

### Key decisions:
- "盛大的仪式" → "grand ceremonies" (not "big events" — literary register)
- "由衷的" → "spoken from the heart" (more vivid than "sincere")
- "悄无声息的" → "happen in silence" (dynamic, not static)
- "山水" → cultural adaptation: "paths we leave behind" — same emotional weight in English imagery
- "等到最后" → "Only later" (avoids death connotation of "at the end")
- "等，等" → single "waited" (English doesn't double verbs for emphasis)

### Example 2: Love prose with parallel structures

Input:
> 你问我为什么喜欢你，
> 比起你的长相，你带给我的感觉。
> 喜欢你没有理由，是炽热又纯粹的爱。
> 便是喜欢全部。
> 是满眼藏不住的爱，是时刻的想念，
> 是止不住的分享欲，是细水长流，是无可替代。
> 你永远是唯一。

First draft:
> You ask me why I love you.
> More than the way you look — the way you make me feel.
> Loving you needs no reason. It is a love that burns bright and pure.
> To love you is to love all of you.
> A love that fills my eyes and cannot be hidden.
> A longing that lives in every moment.
> A desire to share that cannot be stopped.
> A stream that flows slow and steady. That which can never be replaced.
> You will always be the only one.

After review (applying Chinglish patterns reference):
> You ask me why I love you.
> It is not just your appearance, but the way you make me feel.
> Loving you needs no reason. It is a love that burns bright and pure.
> To love you is to love all of you.
> A love that shines through my eyes and cannot be hidden.
> A longing that exists in every moment.
> An endless urge to share every little thing with you.
> A love that grows quietly over time. A love that can never be replaced.
> You will always be my one and only.

### Key fixes applied:
- Fragment fix: "More than the way you look —" → "It is not just your appearance, but..."
- Image transfer: "fills my eyes" → "shines through my eyes" (English idiom)
- Cultural context: "desire to share" → "urge to share every little thing" (分享欲 = youth culture "tell you everything")
- Idiom replacement: "stream flows slow and steady" → "grows quietly over time" (细水长流 = enduring love, not literal water)
- Idiom: "the only one" → "my one and only" (natural English love phrase)
- Chinese parallel structures (是...是...是...) → varied English sentence shapes

## Reference Files

- `references/glossary-zh-en.md` — 成语 and literary terms with non-obvious English equivalents. Build over time.
- `references/chinglish-patterns.md` — Common Chinese→English error patterns with fixes.

## Pre-Flight Checklist

- [ ] Every Chinese sentence → English sentence
- [ ] Numbers, dates, names match original
- [ ] No Chinglish: articles, comma splices, dangling topics fixed
- [ ] 成语 adapted, not literal-translated
- [ ] Emotional tone matches original
- [ ] Tenses consistent
- [ ] Reads like native English, not translated text
