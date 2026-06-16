---
name: desktop-output-rule
description: 桌面输出规则：多个文件建文件夹，单文件可直接放桌面
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 97b1a692-ccce-4ddb-b101-9d72d6dab43e
---

# 桌面输出规则

把产出放到桌面时：

- **多个文件**（≥2 个）→ 在桌面建一个文件夹，全部放进去。文件夹名用英文 kebab-case，如 `voice-samples`、`translation-outputs`
- **单个文件** → 可以直接放桌面

**Why:** 桌面上撒一堆同类文件很乱，用户要一个一个删。建文件夹整洁，一键就能清理整组产出。

**How to apply:** 每次输出到桌面前，先数文件数量。≥2 个就 `mkdir ~/Desktop/<name>` 再放进去。
