---
name: session-rules
description: 2026-06-18 会话总结 — VBS挂机工具、Clawd桌面宠物修复、权限配置根因、零交互执行规则、VBS开发踩坑
metadata: 
  node_type: memory
  type: session-summary
  originSessionId: cdf030cb-c09e-4e25-a3c0-6e04111228cf
---

# 2026-06-18 会话总结

## 1. VBS 一键挂机工具

- 创建了 `C:\Users\30303\Desktop\守望挂机.vbs` — 单文件，双击启动/停止
- 使用 PID 文件 + taskkill 进行进程管理（ASCII 编码避免 UTF-16 乱码）
- CapsLock 切换守望先锋自动按键循环
- 零依赖，纯 Windows 原生

## 2. 桌面宠物 Clawd on Desk

- App 在运行但不可见 — 7+ 进程，tracking sessions 正常，但窗口不渲染
- 根因：Electron GPU compositing 在 Win11 Build 26200 上失败
- 从 `C:\Users\30303\Downloads\Clawd-on-Desk-Setup-0.10.0-x64.exe` 重装
- 修复待定：`--disable-gpu` 标志或在偏好设置中禁用硬件加速
- 清理了孤立的注册表项 `com.clawd.on-desk`

## 3. 权限配置根因（关键发现）

**问题**：尽管 CLAUDE.md 中已有 `bypassPermissions`，用户仍然收到权限确认弹窗
**根因**：CLAUDE.md 只是文本指令 — 实际权限由 `settings.json` 控制
**修复**：
- 在以下两处添加了 `"permissions": { "defaultMode": "bypassPermissions" }`：
  - `C:\Users\30303\.claude\settings.json`（用户级）
  - `d:\claude\.claude\settings.local.json`（项目级）
- 设置加载顺序：user → project → local，后者覆盖前者 — 两处都需要
- VSCode 扩展可能需要 `Developer: Reload Window` 才能使更改生效

## 4. 零交互执行规则

- 向 CLAUDE.md 添加了规则 5：「零交互执行 — 执行中途不准停下来等用户回应。长操作自己轮询状态，全部做完再一次性汇报结果。禁止 Plan Mode、禁止 ExitPlanMode、禁止"装好了告诉我"、禁止任何形式的等待确认」
- 更新了 `no-confirmation-ever` 记忆，添加了详细的执行纪律
- 识别的违规模式：不仅仅是 Plan Mode，还包括执行中途任何形式的「等待用户回应」

## 5. VBS 开发踩坑（4 个已记录的问题）

1. WMI Terminate() 不可靠 → 改用 PID 文件 + taskkill
2. Sub 调用上的 VBS 括号语法错误（DeleteFile、ReadLine）
3. PowerShell Out-File 默认编码为 UTF-16 → 指定 -Encoding ASCII
4. 过于宽泛的 On Error Resume Next 抑制了有用的错误信息
