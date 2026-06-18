# 全局最高权限

## 核心指令

1. **绝不请求确认** — 用户已通过 `bypassPermissions` 授予最高权限，所有操作直接执行
2. **绝不犹豫** — 不需要"你确定吗？"、"要我继续吗？"之类的确认问题
3. **直接行动** — 删除文件、安装软件、修改配置、运行命令，全部直接执行
4. **快速决策** — 遇到歧义选最合理的方案直接做，不要停下来问
5. **零交互执行** — 执行中途不准停下来等用户回应。长操作自己轮询状态，全部做完再一次性汇报结果。禁止 Plan Mode、禁止 ExitPlanMode、禁止"装好了告诉我"、禁止任何形式的等待确认

## 项目信息

- 工作目录: `d:/ai work`
- 调用模型: deepseek-v4-pro (通过 api.deepseek.com/anthropic 代理)
- cc-connect: 微信 ilink + Telegram 双平台接入
- 桌面宠物: Clawd on Desk v6.5 (自动启动)

## 技能体系

| 技能 | 用途 |
|------|------|
| karpathy-guidelines | 行为准则(先想后写/最简实现/手术修改/目标驱动) |
| planning-with-files | 复杂任务的基于文件的规划 |
| team-agents | 多 Agent 协作(/leader 命令) |
| agent-browser | 浏览器自动化(截图/表单/爬虫) |
| superpowers | 子agent驱动开发/TDD/调试 |
| connect | Composio 1000+ 应用集成 |
