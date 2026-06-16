# Claude Code Config Sync

Cross-device sync for Claude Code configuration: skills, settings, memory, plugins.

## Quick Start

### New device (first time)
```powershell
git clone git@github.com:<user>/claude-config-sync.git $env:USERPROFILE\.claude-config-sync
cd $env:USERPROFILE\.claude-config-sync
.\setup.ps1
```

### Push changes (from any device)
```powershell
cd $env:USERPROFILE\.claude-config-sync
.\push.ps1
```

### Pull changes (update existing device)
```powershell
cd $env:USERPROFILE\.claude-config-sync
git pull
.\sync-down.ps1
```

## What's Synced

| What | Path |
|------|------|
| Skills (51) | `skills/` |
| Global instructions | `CLAUDE.md` |
| Settings template | `settings.template.json` |
| Cross-session memory | `memory/` |
| Plugin registry | `plugins/installed_plugins.json` |
| Connect skills | `connect/`, `connect-apps/` |
| Custom scripts | `scripts/` |

## What's NOT Synced

- API keys (stripped from settings, stored as placeholders)
- Plugin caches and marketplaces (reclonable)
- Session transcripts and telemetry
- Device-specific overrides (`settings.local.json`)
- Nested `.git/` directories in skills

## Security

- `settings.json` and `settings.local.json` are in `.gitignore`
- `settings.template.json` has `YOUR_XXX_HERE` placeholders
- `setup.ps1` asks for real keys interactively
- `push.ps1` automatically strips keys before commit
