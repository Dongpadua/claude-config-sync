#!/usr/bin/env node
/* remote-skill-update-checker v1 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const DEFAULT_COOLDOWN_MS = 24 * 60 * 60 * 1000; // 1 day

function parseArgs(argv) {
  const args = new Set(argv.slice(2));
  return {
    force: args.has('--force') || args.has('-f'),
    verbose: args.has('--verbose') || args.has('-v'),
  };
}

function readJson(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    const txt = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(txt);
  } catch {
    return null;
  }
}

function writeJson(filePath, obj) {
  try {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, JSON.stringify(obj, null, 2), 'utf-8');
  } catch {
    // ignore
  }
}

function getManifestPaths() {
  const cwd = process.cwd();
  return Array.from(
    new Set([
      path.join(os.homedir(), '.claude', 'skills', '.skills-manifest.json'),
      path.join(cwd, '.claude', 'skills', '.skills-manifest.json'),
    ])
  );
}

function getRemoteSourcesFromManifest(manifest) {
  const skills = manifest && typeof manifest.skills === 'object' ? manifest.skills : {};
  const sources = [];
  for (const v of Object.values(skills || {})) {
    if (!v || typeof v !== 'object') continue;
    const s = v.source;
    if (typeof s === 'string' && s.trim()) sources.push(s.trim());
  }
  return Array.from(new Set(sources));
}

function parseRemoteSource(remoteSource) {
  const trimmed = String(remoteSource || '')
    .trim()
    .replace(/^https?:\/\/github\.com\//, '');
  const parts = trimmed.split('/').filter(Boolean);
  if (parts.length < 2) return null;
  const owner = parts[0];
  const repo = parts[1];
  const repoPath = parts.slice(2).join('/') || null;
  return { owner, repo, repoPath };
}

function buildCommitsUrl(remoteSource) {
  const parsed = parseRemoteSource(remoteSource);
  if (!parsed) return null;
  const base =
    'https://api.github.com/repos/' +
    encodeURIComponent(parsed.owner) +
    '/' +
    encodeURIComponent(parsed.repo) +
    '/commits?per_page=1';
  if (!parsed.repoPath) return base;
  return base + '&path=' + encodeURIComponent(parsed.repoPath);
}

function shouldSkipByCooldown(lastCheckedAtIso, now, cooldownMs) {
  if (!lastCheckedAtIso) return false;
  const last = new Date(lastCheckedAtIso);
  if (Number.isNaN(last.getTime())) return false;
  return now.getTime() - last.getTime() < cooldownMs;
}

function fetchText(url) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      url,
      {
        method: 'GET',
        headers: {
          'user-agent': 'claude-skills-remote-update-checker',
          accept: 'application/vnd.github+json',
        },
      },
      (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve(data);
          } else {
            reject(new Error('HTTP ' + (res.statusCode || 0)));
          }
        });
      }
    );
    req.on('error', reject);
    req.end();
  });
}

function extractLatestSha(jsonText) {
  try {
    const data = JSON.parse(jsonText);
    if (Array.isArray(data) && data[0] && typeof data[0] === 'object' && typeof data[0].sha === 'string') {
      return data[0].sha || null;
    }
    return null;
  } catch {
    return null;
  }
}

async function main() {
  const { force, verbose } = parseArgs(process.argv);
  const now = new Date();
  const cooldownMs = DEFAULT_COOLDOWN_MS;

  const manifestPaths = getManifestPaths();
  const updates = [];

  for (const manifestPath of manifestPaths) {
    const manifest = readJson(manifestPath) || {};
    const sources = getRemoteSourcesFromManifest(manifest);
    if (!sources.length) continue;

    manifest.remoteCache = manifest.remoteCache && typeof manifest.remoteCache === 'object' ? manifest.remoteCache : {};

    for (const remoteSource of sources) {
      const prevEntry = manifest.remoteCache[remoteSource] || {};
      const prevSha = prevEntry.lastSeenSha || null;

      const url = buildCommitsUrl(remoteSource);
      if (!url) continue;

      if (!force && shouldSkipByCooldown(prevEntry.lastCheckedAt, now, cooldownMs)) {
        continue;
      }

      try {
        const text = await fetchText(url);
        const latestSha = extractLatestSha(text);

        manifest.remoteCache[remoteSource] = {
          ...prevEntry,
          lastCheckedAt: now.toISOString(),
          ...(latestSha ? { lastSeenSha: latestSha } : {}),
        };
        writeJson(manifestPath, manifest);

        // Baseline: first time seeing sha => do not notify
        if (!prevSha && latestSha) continue;

        if (prevSha && latestSha && prevSha !== latestSha) {
          updates.push({ remoteSource, prevSha, latestSha });
        }
      } catch (e) {
        manifest.remoteCache[remoteSource] = {
          ...prevEntry,
          lastCheckedAt: now.toISOString(),
        };
        writeJson(manifestPath, manifest);
        if (verbose) {
          console.log('[remote-skill-check] error', remoteSource, String(e && e.message ? e.message : e));
        }
      }
    }
  }

  if (updates.length > 0) {
    console.log('\n📡 检测到远程 skill 有更新：');
    for (const u of updates) {
      console.log('  -', u.remoteSource);
      console.log('    ', (u.prevSha || '').slice(0, 7), '->', (u.latestSha || '').slice(0, 7));
    }
    console.log('\n💡 建议重新安装对应 skill 以拉取最新版本（remoteSource 模式不会自动更新）。\n');
    process.exitCode = 0;
  }
}

main().catch(() => {
  // ignore
});
