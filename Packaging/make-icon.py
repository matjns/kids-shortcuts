#!/usr/bin/env python3
"""Draw the Eureka Puzzles app icon and write the macOS icon set.

Run from the repo root: python3 Packaging/make-icon.py  (needs Pillow)
The PNGs are committed so a Mac build does not need Python.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / "Assets.xcassets" / "AppIcon.appiconset"
S = 1024 * 2  # draw at 2x, then shrink for smooth edges


def star(cx, cy, outer, inner):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = outer if i % 2 == 0 else inner
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def draw():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bg = Image.new("RGBA", (S, S))
    top, bottom = (120, 80, 230), (60, 34, 150)
    px = bg.load()
    for y in range(S):
        t = y / (S - 1)
        c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(S):
            px[x, y] = c
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((176, 176, S - 176, S - 176), radius=420, fill=255)
    img.paste(bg, (0, 0), mask)
    d = ImageDraw.Draw(img)
    # Staircase of dots folding into a rectangle: the "Gauss" picture.
    cell = 150
    ox, oy = 560, 760
    for r in range(5):
        for c in range(6):
            x, y = ox + c * cell, oy + r * cell
            box = (x, y, x + cell - 34, y + cell - 34)
            if c <= r:
                d.ellipse(box, fill=(255, 196, 60, 255))
            else:
                d.ellipse(box, fill=(110, 200, 255, 255))
    # Eureka star.
    d.polygon(star(1540, 520, 210, 88), fill=(255, 255, 255, 255))
    return img.resize((1024, 1024), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    big = draw()
    for size in (16, 32, 128, 256, 512):
        big.resize((size, size), Image.LANCZOS).save(OUT / f"icon_{size}x{size}.png")
        big.resize((size * 2, size * 2), Image.LANCZOS).save(OUT / f"icon_{size}x{size}@2x.png")
    print("Wrote", OUT)


if __name__ == "__main__":
    main()
