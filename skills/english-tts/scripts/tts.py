"""English TTS using Microsoft Edge TTS (free neural voices)."""
import asyncio
import argparse
import os
import sys

try:
    import edge_tts
except ImportError:
    print("Installing edge-tts...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "edge-tts", "-q"])
    import edge_tts

VOICES = {
    "jenny": "en-US-JennyNeural",
    "aria": "en-US-AriaNeural",
    "guy": "en-US-GuyNeural",
    "davis": "en-US-DavisNeural",
    "ana": "en-US-AnaNeural",
    "sonia": "en-GB-SoniaNeural",
    "ryan": "en-GB-RyanNeural",
    "natasha": "en-AU-NatashaNeural",
    "william": "en-AU-WilliamNeural",
}


async def tts(text: str, voice: str, rate: str, output: str):
    """Convert text to speech and save as MP3."""
    communicate = edge_tts.Communicate(text, voice, rate=rate)
    await communicate.save(output)
    size_kb = os.path.getsize(output) / 1024
    print(f"Saved: {output} ({size_kb:.0f} KB)")


def main():
    parser = argparse.ArgumentParser(description="English Text-to-Speech (Edge TTS)")
    parser.add_argument("--text", required=True, help="English text to speak")
    parser.add_argument("--voice", default="en-US-JennyNeural",
                        help=f"Voice ID or short name: {', '.join(VOICES.keys())}")
    parser.add_argument("--rate", default="+0%", help="Speed: -30%%, +0%%, +20%%, etc.")
    parser.add_argument("--output", default=None,
                        help="Output MP3 path (default: Desktop/tts_output.mp3)")

    args = parser.parse_args()

    # Resolve voice short name
    voice = VOICES.get(args.voice.lower(), args.voice)

    # Default output to Desktop
    if args.output is None:
        desktop = os.path.join(os.environ.get("USERPROFILE", ""), "Desktop")
        args.output = os.path.join(desktop, "tts_output.mp3")

    # Validate rate format
    rate = args.rate
    if not rate.endswith("%"):
        rate = f"+{rate}%" if not rate.startswith(("-", "+")) else f"{rate}%"

    print(f"Voice: {voice}")
    print(f"Rate:  {rate}")
    print(f"Text:  {args.text[:100]}{'...' if len(args.text) > 100 else ''}")
    print()

    asyncio.run(tts(args.text, voice, rate, args.output))


if __name__ == "__main__":
    main()
