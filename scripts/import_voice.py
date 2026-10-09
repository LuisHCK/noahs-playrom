#!/usr/bin/env python3
"""Split a single narration MP3 into the per-line Farm voice clips.

The recording is one continuous take with short pauses between lines. We detect
the pauses with ffmpeg's silencedetect, cut each line, and encode to mono OGG.

Line order is fixed (see docs/farm-audio-script-<lang>.md):

    1-9   intro, mode_explore, mode_learn, mode_find, question, listen,
          correct, wrong, celebrate
    10-18 names (normal tone):      cow..cat
    19-27 names (question tone):    cow..cat

Usage:
    python3 scripts/import_voice.py <src.mp3> <lang> [--merge I ...] [--expected N]

--merge I   merge detected segment I into the next one (1-based). Use this when a
            line's internal pause is long enough to be detected as a separator.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PHRASES = [
    "intro",
    "mode_explore",
    "mode_learn",
    "mode_find",
    "question",
    "listen",
    "correct",
    "wrong",
    "celebrate",
]
ANIMALS = ["cow", "horse", "hen", "rooster", "duck", "pig", "sheep", "dog", "cat"]

SILENCE_NOISE = "-35dB"
SILENCE_MIN = "0.40"
PAD = 0.03


def targets(lang: str) -> list[Path]:
    farm = ROOT / "assets" / "audio" / lang / "farm"
    result = [farm / f"{name}.ogg" for name in PHRASES]
    result += [farm / "names" / f"{a}.ogg" for a in ANIMALS]
    result += [farm / "names_question" / f"{a}.ogg" for a in ANIMALS]
    return result


def detect_segments(src: Path) -> tuple[list[tuple[float, float]], float]:
    proc = subprocess.run(
        [
            "ffmpeg", "-hide_banner", "-i", str(src),
            "-af", f"silencedetect=noise={SILENCE_NOISE}:d={SILENCE_MIN}",
            "-f", "null", "-",
        ],
        capture_output=True,
        text=True,
    )
    log = proc.stderr

    duration_proc = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", str(src)],
        capture_output=True, text=True,
    )
    duration = float(duration_proc.stdout.strip())

    starts = [float(m) for m in re.findall(r"silence_start:\s*([0-9.]+)", log)]
    ends = [float(m) for m in re.findall(r"silence_end:\s*([0-9.]+)", log)]
    if len(starts) != len(ends):
        raise SystemExit(f"silence parse mismatch: {len(starts)} starts, {len(ends)} ends")

    segments: list[tuple[float, float]] = []
    cursor = 0.0
    for start, end in zip(starts, ends):
        if start > cursor:
            segments.append((cursor, start))
        cursor = end
    if duration > cursor:
        segments.append((cursor, duration))
    return segments, duration


def apply_merges(segments: list[tuple[float, float]], merges: list[int]) -> list[tuple[float, float]]:
    for index in sorted(merges):
        i = index - 1
        if i < 0 or i + 1 >= len(segments):
            raise SystemExit(f"--merge {index} out of range (have {len(segments)} segments)")
        segments[i] = (segments[i][0], segments[i + 1][1])
        del segments[i + 1]
    return segments


def cut(src: Path, start: float, end: float, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    start = max(0.0, start - PAD)
    end = end + PAD
    wav = subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(src),
         "-ss", f"{start:.3f}", "-to", f"{end:.3f}",
         "-ac", "1", "-ar", "44100", "-f", "wav", "-"],
        capture_output=True,
    )
    if wav.returncode != 0:
        raise SystemExit(f"ffmpeg failed for {dest.name}: {wav.stderr.decode()}")
    ogg = subprocess.run(
        ["oggenc", "-Q", "-q", "5", "-o", str(dest), "-"],
        input=wav.stdout, capture_output=True,
    )
    if ogg.returncode != 0:
        raise SystemExit(f"oggenc failed for {dest.name}: {ogg.stderr.decode()}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("src")
    parser.add_argument("lang", choices=["en", "es"])
    parser.add_argument("--expected", type=int)
    parser.add_argument("--merge", type=int, action="append", default=[])
    args = parser.parse_args(argv[1:])

    src = Path(args.src)
    dests = targets(args.lang)
    expected = args.expected or len(dests)

    segments, _ = detect_segments(src)
    print(f"detected {len(segments)} segments (expected {expected})")
    for i, (s, e) in enumerate(segments, 1):
        print(f"  {i:>2}: {s:7.3f} - {e:7.3f}  ({e - s:.3f}s)")

    segments = apply_merges(segments, args.merge)
    if len(segments) != expected:
        print(f"after merges: {len(segments)} segments != expected {expected}", file=sys.stderr)
        return 1

    for (start, end), dest in zip(segments, dests):
        cut(src, start, end, dest)
        print(f"  -> {dest.relative_to(ROOT)}  ({end - start:.2f}s)")

    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
