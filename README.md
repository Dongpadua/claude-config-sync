# Claude Code 跨设备同步

一套 GitHub 私有仓库实现 Claude Code 全配置（技能、设置、记忆、插件）多设备同步。

## 工作原理

```
设备 A ──push.ps1──→ GitHub 私有仓库 ←──git pull── 设备 B
设备 B ──push.ps1──→ GitHub 私有仓库 ←──git pull── 设备 A
```

每台电脑都推同一份配置到同一个仓库，其他设备拉下来就是最新的。不会产生重复文件，不会冲突——跟多人协作写代码完全一样。

---

## 场景一：新电脑首次部署

在新电脑上打开 PowerShell，一步一步执行：

### 1. 确保已安装 Git 和 Claude Code

```powershell
git --version       # 没有就去 https://git-scm.com 下载
claude --version    # Claude Code 需先装好
```

### 2. 克隆同步仓库

```powershell
git clone https://github.com/Dongpadua/claude-config-sync.git "$env:USERPROFILE\.claude-config-sync"
```

如果提示登录，输入 GitHub 账号 `Dongpadua` 和密码/token。

### 3. 一键部署

```powershell
cd "$env:USERPROFILE\.claude-config-sync"
.\setup.ps1
```

输入 DeepSeek API key 后，会自动：
- **设置系统环境变量**（`ANTHROPIC_AUTH_TOKEN` + `ANTHROPIC_BASE_URL`）— 确保首次启动跳过登录
- 写入 settings.json
- 部署全部技能、记忆、插件

### 4. 重启终端 + 启动 Claude Code

**必须重启终端窗口**（环境变量才生效），然后打开 Claude Code 即可自动通过 DeepSeek 登录。

---

## 场景二：日常推送（改完配置后上传）

**在任何一台电脑上**，改完技能、设置、记忆文件后：

```powershell
cd "$env:USERPROFILE\.claude-config-sync"
.\push.ps1
```

脚本自动做 8 件事：
1. 拉取远端最新（防止冲突）
2. 复制 CLAUDE.md + config.json
3. 脱敏 settings.json（API key 替换为占位符）
4. 同步所有技能目录
5. 同步记忆文件
6. 复制插件注册表 + connect + 脚本
7. `git commit`
8. `git push`

**输出绿色 "Pushed successfully" 就完成了。**

> 记不住路径？把这行加到 PowerShell 配置文件里，以后敲 `sync` 就行：
> ```powershell
> # 在 PowerShell 里运行：notepad $PROFILE
> # 粘贴下面这行，保存：
> function sync-claude { Push-Location "$env:USERPROFILE\.claude-config-sync"; .\push.ps1; Pop-Location }
> ```
> 以后直接敲 `sync-claude` 即可推送。

---

## 场景三：其他设备拉取更新

当 A 电脑推送后，B 电脑想同步最新配置：

```powershell
cd "$env:USERPROFILE\.claude-config-sync"
git pull
.\sync-down.ps1
```

`syc-down.ps1` 只更新文件，**不会覆盖你的 API key**（它自动保留本地的 key，只更新其他配置）。更新完重启 Claude Code。

---

## 同步内容清单

| ✅ 同步 | ❌ 不同步 |
|---------|----------|
| 53 个技能 | API 密钥（自动脱敏） |
| CLAUDE.md 全局指令 | 插件缓存（几百MB，可重新下载） |
| settings.json（脱敏版） | 会话记录 |
| 跨会话记忆文件（6个） | 设备专属设置（settings.local.json） |
| 插件注册表 | 备份/遥测/文件历史 |
| connect/composio 配置 | 技能内的 .git 目录 |
| 自定义脚本 | |

---

## 安全机制

三层防护确保密钥不泄露：

1. **`.gitignore`** — `settings.json` 和 `settings.local.json` 永远不会被 git 追踪
2. **模板替换** — `push.ps1` 提交的是 `settings.template.json`，里面 key 都是 `YOUR_XXX_HERE`
3. **交互式输入** — `setup.ps1` 在新设备上现场要 key，不存到仓库里

---

## 快速参考

| 操作 | 命令 |
|------|------|
| **新电脑初始化** | `git clone ...` → `cd ~/.claude-config-sync` → `.\setup.ps1` |
| **推送更新** | `cd ~/.claude-config-sync` → `.\push.ps1` |
| **拉取更新** | `cd ~/.claude-config-sync` → `git pull` → `.\sync-down.ps1` |
| **查看变更历史** | `cd ~/.claude-config-sync` → `git log --oneline -10` |
| **回滚到某次推送** | `cd ~/.claude-config-sync` → `git log` 找 commit → `git checkout <commit> -- .` → `.\sync-down.ps1` |

---

## 常见问题

**Q: 两台电脑同时改了同一个文件怎么办？**
A: `push.ps1` 第一步就是 `git pull`，如果没有冲突自动合并；有冲突会提示你手动解决。

**Q: 新电脑上符号链接技能（co-design 等）怎么办？**
A: `setup.ps1` 会检查目标是否存在，存在则创建符号链接，不存在则创建 `.missing` 提示文件。

**Q: Claude Code 弹出登录页面？**  
A: 说明 env vars 没生效。① 确认已重启终端 ② 运行 `$env:ANTHROPIC_AUTH_TOKEN` 检查是否有值 ③ 如果没有，重新运行 `.\setup.ps1` 或手动设置：`[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "sk-你的key", "User")`。

**Q: 能不能自动定时推送？**
A: 可以。在 Claude Code 里说 "每天自动推送一次"，即可设置 Cron 定时任务。
