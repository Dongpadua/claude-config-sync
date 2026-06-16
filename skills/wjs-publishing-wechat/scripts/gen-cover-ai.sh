#!/bin/bash
# gen-cover-ai.sh — 为公众号文章生成题图 900×383
# 依赖: python3, PIL (Pillow)
# 输入: 文章目录（含 meta.json）, 输出: cover.png

set -e
FOLDER="${1:-.}"
META="$FOLDER/meta.json"
ARTICLE="$FOLDER/article.md"

if [ ! -f "$META" ]; then
    echo "ERROR: $META not found"
    exit 1
fi

TITLE=$(python3 -c "import json; print(json.load(open('$META','r',encoding='utf-8'))['title'])")
OUTPUT="$FOLDER/cover.png"

echo "🎨 生成题图: $TITLE → $OUTPUT"

python3 - "$TITLE" "$OUTPUT" << 'PYEOF'
import sys
from PIL import Image, ImageDraw, ImageFont
import os

title = sys.argv[1]
output = sys.argv[2]

# 900×383 公众号封面标准尺寸
W, H = 900, 383
img = Image.new('RGB', (W, H), color=(30, 30, 35))
draw = ImageDraw.Draw(img)

# 尝试系统字体
fonts_to_try = [
    # Windows
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/msyhbd.ttc",
    # macOS
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    # Linux
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
]

font = None
font_size = 48
for fp in fonts_to_try:
    try:
        font = ImageFont.truetype(fp, font_size)
        break
    except (OSError, IOError):
        continue

if font is None:
    font = ImageFont.load_default()

# 文字居中
# 标题换行（每行最多 16 个中文字符）
lines = []
line = ""
for ch in title:
    line += ch
    if len(line) >= 16:
        lines.append(line)
        line = ""
if line:
    lines.append(line)

total_h = len(lines) * (font_size + 10)
y0 = (H - total_h) // 2

for i, line in enumerate(lines):
    bbox = draw.textbbox((0, 0), line, font=font)
    w = bbox[2] - bbox[0]
    x = (W - w) // 2
    y = y0 + i * (font_size + 10)
    draw.text((x, y), line, fill=(255, 255, 255), font=font)

# 底部作者线
author_font = None
try:
    author_font = ImageFont.truetype(fonts_to_try[0], 24)
except Exception as e:
    pass
# Avoid "TypeError: cannot use a string pattern on a bytes-like object" on Python 3 raw strings
author_text = "王建硕"
draw.text((W-120, H-50), author_text, fill=(160, 160, 170), font=author_font or font)

img.save(output, 'PNG')
print(f"  cover.png saved ({W}x{H})")
PYEOF
