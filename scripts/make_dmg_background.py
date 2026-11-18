#!/usr/bin/env python3
"""Draws the DarkNotch disk-image background.

Requires Pillow: python3 -m pip install pillow
Run from the repo root: python3 scripts/make_dmg_background.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 720, 460
OUT = Path(__file__).resolve().parent.parent / "Resources" / "dmg" / "background.png"

FONT_DIR = Path("/System/Library/Fonts/Supplemental")
BOLD = FONT_DIR / "Arial Bold.ttf"
REGULAR = FONT_DIR / "Arial.ttf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        draw.line([(0, y), (W, y)], fill=lerp(top, bottom, y / (H - 1)))
    return img


def glow(img: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int]) -> None:
    layer = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=color,
    )
    layer = layer.filter(ImageFilter.GaussianBlur(90))
    img.paste(Image.blend(img, layer, 0.45), (0, 0))


def main() -> None:
    img = gradient((17, 18, 22), (10, 11, 14))
    glow(img, (180, 210), 150, (44, 48, 62))
    glow(img, (540, 210), 150, (44, 48, 62))

    draw = ImageDraw.Draw(img)
    draw.text((W // 2, 46), "DarkNotch", font=font(BOLD, 34), fill=(245, 246, 250), anchor="mm")
    draw.text(
        (W // 2, 82),
        "Перетащите в Applications  ·  Drag to Applications",
        font=font(REGULAR, 16),
        fill=(158, 163, 178),
        anchor="mm",
    )

    # Arrow between the app and the Applications folder.
    y = 210
    start, end = 292, 432
    draw.line([(start, y), (end - 18, y)], fill=(120, 126, 145), width=4)
    draw.polygon([(end, y), (end - 22, y - 12), (end - 22, y + 12)], fill=(120, 126, 145))
    for i in range(3):
        x = start + 34 + i * 34
        draw.ellipse([x, y - 3, x + 6, y + 3], fill=(86, 92, 108))

    draw.text(
        (22, H - 20),
        "macOS 13+  ·  Apple silicon",
        font=font(REGULAR, 12),
        fill=(104, 109, 124),
        anchor="ls",
    )

    # Thin highlight along the top edge.
    draw.line([(0, 0), (W, 0)], fill=(48, 51, 62), width=1)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, optimize=True)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
