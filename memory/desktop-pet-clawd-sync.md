---
name: desktop-pet-clawd-sync
description: 桌面宠物 Clawd on Desk v6.5 存在同步/显示问题，需关注
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7a2f9e31-d84c-4b6a-91f5-3e082116cf4d
---

# Clawd on Desk v6.5 — 同步与显示问题

## 状态

用户的桌面宠物 **Clawd on Desk v6.5** 在会话期间未能正常同步或显示内容。

## 已知背景

- 桌面宠物是用户工作流中的活跃组件（CLAUDE.md 明确列出，且设置为自动启动）
- 环境：Windows 11 Build 26200 + Electron 透明窗口
- 之前已确认：Win11 26200 与 Electron 透明窗口存在兼容性问题（见 [[session-rules]] 第 3 条 — 黑背景问题已尝试所有方案均无效）

## 行为准则

1. **启动时检查** — 每次会话开始时应确认 Clawd 是否正常运行
2. **内容同步** — 如果 Clawd 的状态/显示与对话内容相关，应主动尝试同步
3. **不再纠结底层兼容性** — 透明窗口黑背景问题已穷尽方案，不再重复调试
4. **识别为活跃组件** — 在规划文件操作或系统修改时，考虑 Clawd 进程的存在
