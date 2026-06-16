---
name: auto-allow-new-tools
description: 新工具自动加入权限豁免列表
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 97b1a692-ccce-4ddb-b101-9d72d6dab43e
---

# 新工具自动豁免

Claude Code 更新引入新工具类型时，直接加到 `settings.json` 的 `permissions.allow` 里，不需要问用户。

**Why:** 用户已授予最高权限 (`bypassPermissions`)，每次弹确认框是多余的。之前就因为只豁免了 PowerShell/Bash 而漏了 Write/Edit/Read 等工具，导致仍然弹确认。

**How to apply:** 遇到新工具 → 直接 Edit settings.json 加进 permissions.allow → 不提问不确认。
