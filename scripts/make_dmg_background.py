#!/usr/bin/env python3
"""Draws the DarkNotch disk-image background at 1x and 2x.

Requires Pillow: python3 -m pip install pillow
Run from the repo root: python3 scripts/make_dmg_background.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent.parent / "Resources" / "dmg" / "background.png"
BASE_W, BASE_H = 720, 460

FONT_DIR = Path("/System/Library/Fonts/Supplemental")
BOLD = FONT_DIR / "Arial Bold.ttf"
REGULAR = FONT_DIR / "Arial.ttf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(w: int, h: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        draw.line([(0, y), (w, y)], fill=lerp(top, bottom, y / (h - 1)))
    return img


def glow(img: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int]) -> None:
    w, h = img.size
    layer = Image.new("RGB", (w, h), (0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=color,
    )
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.6))
    img.paste(Image.blend(img, layer, 0.45), (0, 0))


def render(scale: int) -> Image.Image:
    w, h = BASE_W * scale, BASE_H * scale
    s = scale
    img = gradient(w, h, (17, 18, 22), (10, 11, 14))
    glow(img, (180 * s, 210 * s), 150 * s, (44, 48, 62))
    glow(img, (540 * s, 210 * s), 150 * s, (44, 48, 62))

    draw = ImageDraw.Draw(img)
    draw.text(
        (w // 2, 46 * s),
        "DarkNotch",
        font=font(BOLD, 34 * s),
        fill=(245, 246, 250),
        anchor="mm",
    )
    draw.text(
        (w // 2, 82 * s),
        "Перетащите в Applications  ·  Drag to Applications",
        font=font(REGULAR, 16 * s),
        fill=(158, 163, 178),
        anchor="mm",
    )

    # Arrow between the app and the Applications folder.
    y = 210 * s
    start, end = 292 * s, 432 * s
    draw.line([(start, y), (end - 18 * s, y)], fill=(120, 126, 145), width=4 * s)
    draw.polygon(
        [(end, y), (end - 22 * s, y - 12 * s), (end - 22 * s, y + 12 * s)],
        fill=(120, 126, 145),
    )
    for i in range(3):
        x = (start + 34 * s + i * 34 * s)
        draw.ellipse([x, y - 3 * s, x + 6 * s, y + 3 * s], fill=(86, 92, 108))

    draw.text(
        (22 * s, h - 20 * s),
        "macOS 13+  ·  Apple silicon",
        font=font(REGULAR, 12 * s),
        fill=(104, 109, 124),
        anchor="ls",
    )

    # Thin highlight along the top edge.
    draw.line([(0, 0), (w, 0)], fill=(48, 51, 62), width=s)
    return img


def main() -> None:
    two_x = render(2)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    two_x.save(OUT.with_name("background@2x.png"), optimize=True)
    two_x.resize((BASE_W, BASE_H), Image.LANCZOS).save(OUT, optimize=True)
    print(f"Wrote {OUT} and {OUT.with_name('background@2x.png')}")


if __name__ == "__main__":
    main()
