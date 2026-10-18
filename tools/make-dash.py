"""Writes assets/dash-x.png and dash-y.png: one period of a dashed 1 px line (DASH opaque
pixels, then GAP clear), across and down, which the package tiles for `border-dashed` sides.
Run with `python3 tools/make-dash.py`, then upload them and update src/Assets.luau.
"""

import struct
import zlib

DASH = 3
GAP = 3


def png(width: int, height: int, alphas: list[int]) -> bytes:
    rows = []
    for y in range(height):
        row = b"\x00" + b"".join(bytes((255, 255, 255, alphas[y * width + x])) for x in range(width))
        rows.append(row)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")


def main() -> None:
    period = [255] * DASH + [0] * GAP
    with open("assets/dash-x.png", "wb") as file:
        file.write(png(len(period), 1, period))
    with open("assets/dash-y.png", "wb") as file:
        file.write(png(1, len(period), period))


main()
