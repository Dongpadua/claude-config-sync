"""RapidOCR video scanner for Douyin: top headers + bottom subtitles + frame differencing.

Usage:
    python ocr_video.py <video_path> [output_json_path]

Example:
    python ocr_video.py d:/ai/work/_temp_vid.mp4 d:/ai/work/_ocr_result.json
"""
import cv2, numpy as np, json, sys, time

def ocr_video(video_path, output_path=None):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"ERROR: Cannot open video: {video_path}")
        return None

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps
    print(f"Video: {duration:.1f}s, {fps:.1f}fps, {total_frames} frames")

    from rapidocr_onnxruntime import RapidOCR
    ocr = RapidOCR()

    results = []
    prev_bottom = None
    prev_top = None
    total_ocr_time = 0
    ocr_calls = 0
    frames_scanned = 0
    frames_skipped = 0

    t0 = time.time()
    for t in range(0, int(duration) + 1, 1):
        cap.set(cv2.CAP_PROP_POS_MSEC, t * 1000)
        ret, frame = cap.read()
        if not ret:
            continue
        frames_scanned += 1
        h, w = frame.shape[:2]

        # Top 30% — headers, titles, account info
        top = frame[0:int(h * 0.3), :]
        top_gray = cv2.cvtColor(top, cv2.COLOR_BGR2GRAY)

        # Bottom 40% — subtitles (cat meme / text overlay style)
        bottom = frame[int(h * 0.55):h, :]
        bottom_gray = cv2.cvtColor(bottom, cv2.COLOR_BGR2GRAY)

        # Frame differencing
        top_changed = prev_top is None or np.mean(cv2.absdiff(top_gray, prev_top)) >= 10
        bottom_changed = prev_bottom is None or np.mean(cv2.absdiff(bottom_gray, prev_bottom)) >= 10

        if not top_changed and not bottom_changed:
            frames_skipped += 1
            continue

        top_small = cv2.resize(top_gray, (top_gray.shape[1] // 2, top_gray.shape[0] // 2))
        bottom_small = cv2.resize(bottom_gray, (bottom_gray.shape[1] // 2, bottom_gray.shape[0] // 2))

        ocr_start = time.time()
        top_result, _ = ocr(top_small) if top_changed else ([], None)
        bottom_result, _ = ocr(bottom_small) if bottom_changed else ([], None)
        elapsed = time.time() - ocr_start
        total_ocr_time += elapsed
        ocr_calls += 1

        top_text = ' | '.join([r[1] for r in top_result]).strip() if top_result else ""
        bottom_text = ' | '.join([r[1] for r in bottom_result]).strip() if bottom_result else ""

        if top_text or bottom_text:
            prev_top = top_gray if top_changed else prev_top
            prev_bottom = bottom_gray if bottom_changed else prev_bottom
            ts = f"{int(t // 60):02d}:{int(t % 60):02d}"
            results.append({"time": t, "timestamp": ts, "top": top_text, "bottom": bottom_text})

    cap.release()
    total_time = time.time() - t0

    print(f"Frames: {frames_scanned} scanned, {frames_skipped} skipped ({frames_skipped * 100 // max(frames_scanned, 1)}%)")
    print(f"OCR: {ocr_calls} calls, {total_ocr_time:.1f}s total, {total_ocr_time / max(ocr_calls, 1):.2f}s avg")
    print(f"Total time: {total_time:.1f}s")
    print(f"Text segments found: {len(results)}")

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        print(f"Saved to: {output_path}")

    return results


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ocr_video.py <video_path> [output_json_path]")
        sys.exit(1)

    video = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else video.rsplit(".", 1)[0] + "_ocr.json"
    ocr_video(video, output)
