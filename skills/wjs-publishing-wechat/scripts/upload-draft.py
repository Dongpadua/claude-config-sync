#!/usr/bin/env python3
"""upload-draft.sh wrapper — 上传草稿到微信公众号后台。
Python 实现，避免 bash 的 JSON 转义问题。
依赖: requests, Pillow
"""
import json, os, sys, time
import requests

# Fix Windows console encoding
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

CONFIG_PATH = os.path.expanduser("~/.wechat-mp-config.json")
ACCESS_TOKEN_CACHE = os.path.expanduser("~/.wechat-mp-token.json")

def get_access_token(appid: str, secret: str) -> str:
    """获取或缓存 access_token（2小时有效）"""
    if os.path.exists(ACCESS_TOKEN_CACHE):
        with open(ACCESS_TOKEN_CACHE, encoding="utf-8") as f:
            cache = json.load(f)
        if cache.get("expires_at", 0) > time.time():
            return cache["access_token"]

    url = "https://api.weixin.qq.com/cgi-bin/token"
    params = {"grant_type": "client_credential", "appid": appid, "secret": secret}
    resp = requests.get(url, params=params, timeout=15).json()

    if "errcode" in resp and resp["errcode"] != 0:
        print(f"ERROR getting access_token: {resp.get('errmsg', resp)}")
        sys.exit(1)

    token = resp["access_token"]
    expires = resp.get("expires_in", 7200)  # default 2 hours

    with open(ACCESS_TOKEN_CACHE, "w") as f:
        json.dump({
            "access_token": token,
            "expires_at": time.time() + expires - 300  # 5 min buffer
        }, f)

    return token

def upload_image(access_token: str, image_path: str) -> str:
    """上传图片到微信服务器，返回 media_id (URL 格式)"""
    url = f"https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token={access_token}"
    with open(image_path, "rb") as f:
        files = {"media": (os.path.basename(image_path), f, "image/png")}
        resp = requests.post(url, files=files, timeout=30).json()

    if "errcode" in resp and resp["errcode"] != 0:
        print(f"ERROR uploading image: {resp.get('errmsg', resp)}")
        sys.exit(1)

    return resp.get("url", "")

def upload_thumb_image(access_token: str, image_path: str) -> str:
    """上传封面图（永久素材），返回 media_id"""
    url = f"https://api.weixin.qq.com/cgi-bin/material/add_material?access_token={access_token}&type=thumb"
    with open(image_path, "rb") as f:
        # 封面图要求 <1MB，先检查
        data = f.read()
        if len(data) > 1024 * 1024:
            print("WARNING: 封面图超过 1MB，微信可能拒绝")
        files = {"media": (os.path.basename(image_path), data, "image/png")}
        resp = requests.post(url, files=files, timeout=30).json()

    if "errcode" in resp and resp["errcode"] != 0:
        print(f"ERROR uploading thumb: {resp.get('errmsg', resp)}")
        sys.exit(1)

    return resp.get("media_id", "")

def add_draft(access_token: str, article: dict) -> str:
    """创建草稿"""
    url = f"https://api.weixin.qq.com/cgi-bin/draft/add?access_token={access_token}"
    body = {"articles": [article]}
    resp = requests.post(url, data=json.dumps(body, ensure_ascii=False).encode('utf-8'),
                         headers={'Content-Type': 'application/json; charset=utf-8'}, timeout=15).json()

    if "errcode" in resp and resp["errcode"] != 0:
        print(f"ERROR adding draft: {resp.get('errmsg', resp)}")
        sys.exit(1)

    return resp.get("media_id", "")

def markdown_to_wechat_html(md_text: str) -> str:
    """简单 Markdown → 微信公众号 HTML"""
    import re

    html = md_text

    # 红色加粗: **text** → <strong style="color:#c0392b;">text</strong>
    html = re.sub(
        r'\*\*(.+?)\*\*',
        r'<strong style="color:#c0392b;">\1</strong>',
        html
    )

    # Headers
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Images
    html = re.sub(r'!\[.*?\]\((.+?)\)', r'<img src="\1" style="max-width:100%;"/>', html)

    # Bold (non-red, basic)
    # already handled above

    # Paragraphs: double newlines
    paragraphs = html.split('\n\n')
    processed = []
    for p in paragraphs:
        p = p.strip()
        if not p:
            continue
        if p.startswith('<h') or p.startswith('<img'):
            processed.append(p)
        else:
            # Replace single newlines with <br/>
            p = p.replace('\n', '<br/>')
            processed.append(f'<section style="margin-bottom:1em;line-height:1.8;">{p}</section>')

    return '\n'.join(processed)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 upload-draft.py <article-folder>")
        print("  Folder must contain: article.md, meta.json, cover.png")
        sys.exit(1)

    folder = sys.argv[1]
    article_path = os.path.join(folder, "article.md")
    meta_path = os.path.join(folder, "meta.json")
    cover_path = os.path.join(folder, "cover.png")

    for f in [article_path, meta_path]:
        if not os.path.exists(f):
            print(f"ERROR: {f} not found")
            sys.exit(1)

    if not os.path.exists(CONFIG_PATH):
        print(f"ERROR: {CONFIG_PATH} not found")
        print("Create it with:")
        print('  {"appid":"wx...","secret":"...","author":"Your Name"}')
        sys.exit(1)

    with open(CONFIG_PATH, encoding="utf-8") as f:
        config = json.load(f)

    with open(article_path, encoding="utf-8") as f:
        md_content = f.read()

    with open(meta_path, encoding="utf-8") as f:
        meta = json.load(f)

    appid = config.get("appid", "")
    secret = config.get("secret", "")
    author = config.get("author", "王建硕")

    if not appid or not secret:
        print("ERROR: appid/secret missing in ~/.wechat-mp-config.json")
        sys.exit(1)

    print("Getting access_token...")
    token = get_access_token(appid, secret)
    print("   OK")

    # Upload cover image
    thumb_media_id = ""
    if os.path.exists(cover_path):
        print("Uploading cover image...")
        thumb_media_id = upload_thumb_image(token, cover_path)
        print(f"   media_id: {thumb_media_id}")
    else:
        print("WARNING: cover.png not found, using no cover")

    # Render HTML
    print("Converting Markdown to HTML...")
    html_content = markdown_to_wechat_html(md_content)

    # Build article
    article = {
        "title": meta.get("title", "Untitled"),
        "author": author,
        "digest": meta.get("summary", "")[:120],
        "content": html_content,
        "content_source_url": meta.get("source_url", ""),
        "need_open_comment": 0,
        "only_fans_can_comment": 0,
    }

    # If we have a cover, determine the show type
    # For the WeChat API thumbnail, image size must be <1MB
    if thumb_media_id:
        article["thumb_media_id"] = thumb_media_id
        article["need_cover"] = 1

    print("Creating draft...")
    print(f"   Title: {article['title']}")
    print(f"   Author: {article['author']}")

    draft_media_id = add_draft(token, article)
    print("\nDraft created!")
    print(f"   draft media_id: {draft_media_id}")
    print("   Check it at mp.weixin.qq.com -> Drafts")

if __name__ == "__main__":
    main()
