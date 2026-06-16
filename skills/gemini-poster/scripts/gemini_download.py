#!/usr/bin/env python3
"""Download full-size Gemini-generated image via CDP, then enhance + watermark."""
import json, os, sys, time, shutil
from PIL import Image, ImageEnhance

CDP_PORT = os.environ.get("CDP_PORT", "9222")
OUT_DIR = os.path.expanduser(os.environ.get("OUT_DIR", r"~\Desktop\海报"))
WATERMARK_PATH = os.path.expanduser(r"~\Desktop\公众号\顺新文旅.png")
WATERMARK_RATIO = 0.24  # of image width
SHARPEN_FACTOR = 2.0
CONTRAST_FACTOR = 1.1
PADDING = 40


def cdp_get_json(path):
    import requests
    return requests.get(f"http://127.0.0.1:{CDP_PORT}{path}", timeout=10).json()


def cdp_ws_call(expression, await_promise=True):
    from websocket import create_connection
    pages = cdp_get_json("/json")
    gemini = [p for p in pages if "gemini" in p.get("url", "")]
    if not gemini:
        print("ERROR: No Gemini tab found")
        return None
    ws = create_connection(gemini[0]["webSocketDebuggerUrl"], origin=f"http://127.0.0.1:{CDP_PORT}")
    msg = {"id": 1, "method": "Runtime.evaluate", "params": {
        "expression": expression, "awaitPromise": await_promise, "returnByValue": True
    }}
    ws.send(json.dumps(msg))
    result = json.loads(ws.recv())
    ws.close()
    return result.get("result", {}).get("result", {}).get("value")


def click_download():
    """Click the 'Download full-size image' button on Gemini page."""
    print("Clicking download button...")
    expression = """
    (() => {
        const btns = document.querySelectorAll('button');
        for (const b of btns) {
            if (b.getAttribute('aria-label') === '下载完整尺寸的图片') {
                b.click();
                return true;
            }
        }
        return false;
    })()
    """
    return cdp_ws_call(expression, await_promise=False)


def find_downloaded_file(before_files):
    """Find the new file in Downloads folder."""
    downloads = os.path.expanduser(r"~\Downloads")
    after = set(os.listdir(downloads))
    new = after - before_files
    for f in new:
        path = os.path.join(downloads, f)
        if f.startswith("Gemini_Generated") and f.endswith(".png"):
            return path
    return None


def enhance_image(src, dst):
    """Apply sharpening and contrast enhancement."""
    img = Image.open(src)
    img = ImageEnhance.Sharpness(img).enhance(SHARPEN_FACTOR)
    img = ImageEnhance.Contrast(img).enhance(CONTRAST_FACTOR)
    img.save(dst, "PNG")
    return img


def add_watermark(src, dst):
    """Add watermark to image."""
    if not os.path.exists(WATERMARK_PATH):
        print(f"Watermark not found: {WATERMARK_PATH}")
        return
    img = Image.open(src)
    wm = Image.open(WATERMARK_PATH).convert("RGBA")
    tw = int(img.width * WATERMARK_RATIO)
    wm = wm.resize((tw, int(wm.height * tw / wm.width)), Image.LANCZOS)
    ir = img.convert("RGBA")
    ir.paste(wm, (PADDING, PADDING), wm)
    ir.save(dst, "PNG")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. Snapshot Downloads before
    downloads = os.path.expanduser(r"~\Downloads")
    before = set(os.listdir(downloads))

    # 2. Click download on Gemini
    if not click_download():
        print("ERROR: Could not click download button. Is Gemini page open with a generated image?")
        sys.exit(1)

    # 3. Wait for download
    print("Waiting for download...")
    for _ in range(30):
        time.sleep(1)
        path = find_downloaded_file(before)
        if path:
            print(f"Downloaded: {path} ({os.path.getsize(path)//1024} KB)")
            break
    else:
        print("ERROR: Download not detected within 30s")
        sys.exit(1)

    # 4. Copy original
    orig = os.path.join(OUT_DIR, "gemini_orig.png")
    shutil.copy2(path, orig)
    img = Image.open(orig)
    print(f"Original: {img.size} -> {orig}")

    # 5. Enhance
    sharp = os.path.join(OUT_DIR, "gemini_sharp.png")
    enhance_image(orig, sharp)
    print(f"Enhanced: {sharp} ({os.path.getsize(sharp)//1024} KB)")

    # 6. Watermark
    final = os.path.join(OUT_DIR, "gemini_final.png")
    add_watermark(sharp, final)
    print(f"Final: {final} ({os.path.getsize(final)//1024} KB)")

    # 7. Clean up download
    os.remove(path)
    print("Done! Files in " + OUT_DIR)


if __name__ == "__main__":
    main()
