#!/usr/bin/env python3
"""Chroma-key flat background (color sampled from image borders) -> transparent PNG."""
import sys
import statistics
from collections import deque
from PIL import Image

def process(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    pixels = im.load()

    # 1) цвет фона = медианы пикселей по периметру
    border = []
    for x in range(w):
        border += [pixels[x, 0], pixels[x, h - 1]]
    for y in range(h):
        border += [pixels[0, y], pixels[w - 1, y]]
    br = statistics.median(p[0] for p in border)
    bg_ = statistics.median(p[1] for p in border)
    bb = statistics.median(p[2] for p in border)

    T = 45  # допуск по каждому каналу (бинарная заливка)

    def is_bg(px):
        r, g, b = px[:3]
        return abs(r - br) < T and abs(g - bg_) < T and abs(b - bb) < T

    # 2) flood fill от краёв
    bgmap = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or bgmap[y][x]:
            continue
        if not is_bg(pixels[x, y]):
            continue
        bgmap[y][x] = True
        q.extend([(x+1, y), (x-1, y), (x, y+1), (x, y-1)])

    # 3) альфа: бинарная — фон прозрачный, остальное непрозрачное
    out = Image.new("RGBA", (w, h))
    out_pixels = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y]
            out_pixels[x, y] = (r, g, b, 0 if bgmap[y][x] else 255)

    # 4) закрытие тонких дыр
    for _ in range(3):
        changed = False
        to_fill = []
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if out_pixels[x, y][3] != 0:
                    continue
                opaque = sum(1 for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                             if (dx or dy) and out_pixels[x + dx, y + dy][3] > 200)
                if opaque >= 5:
                    to_fill.append((x, y))
        for x, y in to_fill:
            r, g, b, _ = out_pixels[x, y]
            out_pixels[x, y] = (r, g, b, 255)
            changed = True
        if not changed:
            break

    # 5) оставляем только самый большой непрозрачный компонент (убирает вотермарки)
    labels = [[0] * w for _ in range(h)]
    comps = []
    for yy in range(h):
        for xx in range(w):
            if labels[yy][xx] == 0 and out_pixels[xx, yy][3] > 0:
                comp_id = len(comps) + 1
                stack = [(xx, yy)]
                pixels_list = []
                labels[yy][xx] = comp_id
                while stack:
                    cx, cy = stack.pop()
                    pixels_list.append((cx, cy))
                    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and labels[ny][nx] == 0 and out_pixels[nx, ny][3] > 0:
                            labels[ny][nx] = comp_id
                            stack.append((nx, ny))
                comps.append(pixels_list)

    if comps:
        largest = max(comps, key=len)
        for pixels_list in comps:
            if pixels_list is largest:
                continue
            for cx, cy in pixels_list:
                r, g, b, _ = out_pixels[cx, cy]
                out_pixels[cx, cy] = (r, g, b, 0)

    # 6) обрезка до содержимого
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    out.save(path)
    print(f"processed {path} -> {out.size} (bg=({br},{bg_},{bb}))")

if __name__ == "__main__":
    for p in sys.argv[1:]:
        process(p)
