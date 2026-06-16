#!/usr/bin/env python3
"""盘古之白 — 中英文之间自动补空格。幂等，重复跑不会多余加空格。"""
import re, sys

def pangu(text: str) -> str:
    """在中文和英文/数字之间添加空格"""
    # 中文 + 英文
    text = re.sub(r'([一-鿿㐀-䶿])([a-zA-Z])', r'\1 \2', text)
    text = re.sub(r'([a-zA-Z])([一-鿿㐀-䶿])', r'\1 \2', text)
    # 中文 + 数字
    text = re.sub(r'([一-鿿㐀-䶿])(\d)', r'\1 \2', text)
    text = re.sub(r'(\d)([一-鿿㐀-䶿])', r'\1 \2', text)
    # 清理多余空格
    text = re.sub(r' {2,}', ' ', text)
    return text

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: pangu.py <file>")
        sys.exit(1)
    path = sys.argv[1]
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    result = pangu(content)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(result)
    print(f"盘古之白 done: {path}")
