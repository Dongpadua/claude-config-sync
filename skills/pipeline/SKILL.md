---
name: pipeline
description: 一键全自动开发流水线——从 GitHub Issue 到 PR 合并，AI 独立完成全流程：读需求→拆任务→拉分支→写代码→审查→修复→PR。触发词："/pipeline"、"一键开发"、"自动完成"、"实现这个issue"、"端到端"。
---

# Pipeline — 全自动 AI 开发流水线

一句话触发端到端开发：给定 GitHub Issue URL，AI 自动走完整条产线。

## 流水线阶段

```
Issue URL → [1分析] → [2规划] → [3开发] → [4审查] → [5修复] → [6PR] → 完成
```

## 阶段详解

### Stage 1 — ANALYZE：读需求
- 读取 GitHub Issue 内容（标题、描述、标签、评论）
- 提取功能需求、验收标准、边界条件
- 识别技术栈（从仓库文件推断）
- 输出：需求摘要（3-5 句话）

### Stage 2 — PLAN：拆任务
- 将需求拆解为可独立实现的子任务
- 每个子任务 ≤200 行代码
- 确定文件变更列表（新建/修改/删除）
- 输出：任务清单 + 文件变更计划

### Stage 3 — DEVELOP：写代码
- 创建功能分支 `feat/<issue-number>-<slug>`
- 按任务顺序逐个实现
- 每个任务完成后 git commit
- 写测试（如果语言有测试框架）
- 输出：分支名 + commit 列表

### Stage 4 — REVIEW：交叉审查
- GPT-4o 审查代码质量（免费）
- Sonnet 审查逻辑正确性
- Gemini Flash 审查安全漏洞（免费）
- 汇总问题列表，按严重程度排序
- 输出：审查报告（评分 + 问题列表）

### Stage 5 — FIX：修复问题
- CRITICAL/HIGH 问题必须修复
- MEDIUM 问题尝试修复
- LOW 问题记录为 TODO
- 修复后重新 commit
- 输出：修复记录

### Stage 6 — PR：提交 Pull Request
- Push 分支到 GitHub
- 创建 PR（自动填充描述：需求摘要 + 变更列表 + 审查结果）
- 关联原始 Issue（`Closes #N`）
- 输出：PR URL

## 调用方式

```
/pipeline https://github.com/owner/repo/issues/123
```

或描述需求：
```
/pipeline 给这个仓库加一个用户登录功能
```

## 质量门禁

PR 创建前的硬性要求：
- [ ] 交叉审查 ≥2/3 PASS
- [ ] 无 CRITICAL 问题
- [ ] 所有 commit 有意义的 message
- [ ] PR 描述包含需求摘要 + 变更列表

## 快捷命令

| 命令 | 作用 |
|------|------|
| `/pipeline <url>` | 从 Issue 开始完整流水线 |
| `/pipeline resume` | 从上次中断处继续 |
| `/pipeline review` | 只跑审查阶段 |
| `/pipeline status` | 查看当前流水线状态 |

## 注意事项

- 每个阶段完成后汇报进度
- 遇到阻塞（权限、依赖、不明确的规格）立即告诉用户
- 审查发现 CRITICAL 问题时自动进入修复循环（最多 3 次）
- 3 次修复仍未通过 → 暂停，标记问题，请求用户介入
- 整个过程记录到 `.pipeline/run-<timestamp>.md`
