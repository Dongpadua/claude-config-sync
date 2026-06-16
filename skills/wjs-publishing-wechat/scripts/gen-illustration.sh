#!/bin/bash
# gen-illustration.sh — 为公众号文章生成插图
# 用 Pillow 生成一张简单插画，确保 article.md 引用 ![](./illustration.png)
set -e
FOLDER="${1:-.}"
META="$FOLDER/meta.json"
ARTICLE="$FOLDER/article.md"
OUTPUT="$FOLDER/illustration.png"

if [ ! -f "$META" ]; then
    echo "ERROR: $META not found"
    exit 1
fi

echo "🎨 生成插图 → $OUTPUT"

python3 - "$FOLDER" << 'PYEOF'
import sys, os, json, re

folder = sys.argv[1]
meta_path = os.path.join(folder, 'meta.json')
article_path = os.path.join(folder, 'article.md')
output = os.path.join(folder, 'illustration.png')

with open(meta_path, 'r', encoding='utf-8') as f:
    meta = json.load(f)

with open(article_path, 'r', encoding='utf-8') as f:
    article = f.read()

# 如果已有插图引用,跳过
if 'illustration.png' in article:
    print("  illustration.png already referenced, skip")
    sys.exit(0)

from PIL import Image, ImageDraw

W, H = 600, 400
img = Image.new('RGB', (W, H), color=(245, 248, 250))
draw = ImageDraw.Draw(img)

# 简洁装饰
for i in range(6):
    y = 50 + i * 55
    draw.rectangle([60, y, 540, y+3], fill=(80, 140, 210, min(255, 200 - i*25)))

# 标题文字
fonts_to_try = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "/System/Library/Fonts/PingFang.ttc",
]
font = None
for fp in fonts_to_try:
    try:
        from PIL import ImageFont
        font = ImageFont.truetype(fp, 32)
        break
    except Exception as e:
        continue
if font is None:
    font = ImageDraw.ImageFont.load_default()  # type: ignore[attr-defined]

title = meta.get('title', '')
draw.text((60, 360), title[:20], fill=(60, 60, 70), font=font)

img.save(output, 'PNG')
print(f"  illustration.png saved ({W}x{H})")
PYEOF

# 在 article.md 末尾加引用
if ! grep -q 'illustration.png' "$ARTICLE"; then
    echo "" >> "$ARTICLE"
    echo "![](./illustration.png)" >> "$ARTICLE"
    echo "  appended illustration ref to article.md"
fi
