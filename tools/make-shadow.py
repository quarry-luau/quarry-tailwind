"""Writes assets/shadow/c<corner>.png: white rounded boxes blurred as CSS blurs a box-shadow,
for the shadows to 9-slice, one per corner radius in CORNERS.

CSS draws a shadow of blur radius B as the shadow box under a Gaussian blur of standard
deviation B / 2. Each image is that for B = REFERENCE_BLUR: a square canvas whose box starts
MARGIN pixels in, with corners of the given radius, blurred with sigma = REFERENCE_BLUR / 2, so
the falloff runs from MARGIN - REFERENCE_BLUR to MARGIN + REFERENCE_BLUR. The package draws blur B with
SliceScale B / REFERENCE_BLUR, which scales the corner too, so it picks the image whose corner,
scaled, is nearest the element's radius without passing it. The blur reaches INNER pixels (3
sigma) inside the box, so each image 9-slices at MARGIN + corner + INNER, leaving CENTRE opaque
pixels in the middle. Run with `python3 tools/make-shadow.py`, then upload them and update src/Assets.luau.
"""

import math
import struct
import zlib

MARGIN = 32
REFERENCE_BLUR = 16
INNER = 24
CENTRE = 8
CORNERS = [0, 8, 16, 24, 32, 48, 64, 96, 128, 192, 256]
OUTPUT = "assets/shadow/c{corner}.png"


def inside(x: float, y: float, corner: int, canvas: int) -> float:
    """1 inside the rounded box, 0 outside."""
    low, high = MARGIN, canvas - MARGIN
    cx = min(max(x, low + corner), high - corner)
    cy = min(max(y, low + corner), high - corner)
    within = low <= x <= high and low <= y <= high
    return 1.0 if within and math.hypot(x - cx, y - cy) <= corner else 0.0


def blur(rows: list[list[float]], sigma: float) -> list[list[float]]:
    canvas = len(rows)
    radius = int(math.ceil(sigma * 3))
    kernel = [math.exp(-(i * i) / (2 * sigma * sigma)) for i in range(-radius, radius + 1)]
    total = sum(kernel)
    kernel = [k / total for k in kernel]

    def pass_(data: list[list[float]]) -> list[list[float]]:
        out = []
        for row in data:
            line = []
            for x in range(canvas):
                value = 0.0
                for i, k in enumerate(kernel):
                    sx = x + i - radius
                    if 0 <= sx < canvas:
                        value += row[sx] * k
                line.append(value)
            out.append(line)
        return out

    horizontal = pass_(rows)
    transposed = [list(column) for column in zip(*horizontal)]
    return [list(column) for column in zip(*pass_(transposed))]


def png(alpha: list[list[float]]) -> bytes:
    raw = b"".join(
        b"\x00" + b"".join(bytes((255, 255, 255, round(min(max(a, 0.0), 1.0) * 255))) for a in row) for row in alpha
    )

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", len(alpha[0]), len(alpha), 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def image(corner: int) -> list[list[float]]:
    canvas = 2 * (MARGIN + corner + INNER) + CENTRE
    # Sampled 4x4 per pixel, so the corner is smooth before the blur.
    rows = []
    for y in range(canvas):
        row = []
        for x in range(canvas):
            hits = sum(inside(x + (i + 0.5) / 4, y + (j + 0.5) / 4, corner, canvas) for i in range(4) for j in range(4))
            row.append(hits / 16)
        rows.append(row)
    return blur(rows, REFERENCE_BLUR / 2)


def main() -> None:
    for corner in CORNERS:
        with open(OUTPUT.format(corner=corner), "wb") as file:
            file.write(png(image(corner)))


main()
