#!/usr/bin/env python3
"""Slice the 3x3 sprite sheet into 9 transparent PNGs using rembg."""

from pathlib import Path
import sys

import numpy as np
from PIL import Image
from rembg import remove, new_session

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "kitagawaasset.jpeg"
OUT = ROOT / "assets" / "sprites"

ROW_LABELS = ["idle", "right", "left"]
COLS = 3
ROWS = 3
MODEL = "u2net"  # cleaner cutouts for this pixel-art sheet (isnet-anime washes character out)


def keep_largest_component(img: Image.Image) -> Image.Image:
    """Keep only the largest connected blob of non-transparent pixels.

    Uses a pure-numpy iterative two-pass labeling (4-connectivity) so we don't
    pull in scipy. The label-text artifacts from the source sheet ("Idle",
    "Walk Right", "Walk Left") form smaller blobs separate from the character
    and get dropped.
    """
    arr = np.array(img)
    h, w = arr.shape[:2]
    alpha = arr[..., 3] > 0
    if not alpha.any():
        return img

    # Flood-fill from each unvisited foreground pixel using a numpy stack.
    labels = np.zeros((h, w), dtype=np.int32)
    next_label = 0
    sizes = [0]

    fg = alpha.copy()
    ys, xs = np.where(fg)
    visited = np.zeros_like(fg)

    for sy, sx in zip(ys, xs):
        if visited[sy, sx]:
            continue
        next_label += 1
        size = 0
        stack = [(sy, sx)]
        while stack:
            y, x = stack.pop()
            if y < 0 or y >= h or x < 0 or x >= w:
                continue
            if visited[y, x] or not fg[y, x]:
                continue
            visited[y, x] = True
            labels[y, x] = next_label
            size += 1
            stack.append((y + 1, x))
            stack.append((y - 1, x))
            stack.append((y, x + 1))
            stack.append((y, x - 1))
        sizes.append(size)

    if next_label == 0:
        return img

    largest = int(np.argmax(sizes[1:])) + 1
    mask = labels == largest
    arr[..., 3] = (arr[..., 3] * mask).astype(arr.dtype)
    return Image.fromarray(arr)


def union_bbox(boxes):
    xs0 = min(b[0] for b in boxes)
    ys0 = min(b[1] for b in boxes)
    xs1 = max(b[2] for b in boxes)
    ys1 = max(b[3] for b in boxes)
    return (xs0, ys0, xs1, ys1)


def main() -> int:
    if not SRC.exists():
        print(f"missing source: {SRC}", file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)

    print(f"loading {SRC.name}...")
    sheet = Image.open(SRC).convert("RGB")
    w, h = sheet.size
    cw, ch = w // COLS, h // ROWS
    print(f"sheet {w}x{h}, cell {cw}x{ch}")

    session = new_session(MODEL)

    cutouts: dict[tuple[int, int], Image.Image] = {}
    bboxes: list[tuple[int, int, int, int]] = []

    print("running rembg on 9 cells...")
    for row in range(ROWS):
        for col in range(COLS):
            box = (col * cw, row * ch, (col + 1) * cw, (row + 1) * ch)
            cell = sheet.crop(box)
            cutout = remove(cell, session=session, alpha_matting=False)
            cutout = keep_largest_component(cutout)
            cutouts[(row, col)] = cutout
            bbox = cutout.getbbox()
            if bbox:
                bboxes.append(bbox)
            print(f"  ({row},{col}) bbox={bbox}")

    # Per-row centroid alignment: shift each frame so the character's centroid
    # in X matches the row's reference X. This kills horizontal jitter that the
    # eye reads as the body wobbling left-right during walking.
    print("aligning centroids per row...")
    for row in range(ROWS):
        row_cutouts = [(col, cutouts[(row, col)]) for col in range(COLS)]
        cents = []
        for col, cut in row_cutouts:
            arr = np.array(cut)
            ys, xs = np.where(arr[..., 3] > 0)
            if len(xs) == 0:
                cents.append(None)
                continue
            cents.append((float(xs.mean()), float(ys.mean())))
        valid = [c for c in cents if c is not None]
        if not valid:
            continue
        ref_x = sum(c[0] for c in valid) / len(valid)
        ref_y = max(c[1] for c in valid)  # align feet by using the lowest centroid Y
        for col, cut in row_cutouts:
            cent = cents[col]
            if cent is None:
                continue
            dx = int(round(ref_x - cent[0]))
            dy = 0  # leave Y alone — feet should rest on the floor naturally
            if dx == 0 and dy == 0:
                continue
            arr = np.array(cut)
            shifted = np.zeros_like(arr)
            h, w = arr.shape[:2]
            sx0 = max(0, dx); sx1 = min(w, w + dx)
            dx0 = max(0, -dx); dx1 = min(w, w - dx)
            sy0 = max(0, dy); sy1 = min(h, h + dy)
            dy0 = max(0, -dy); dy1 = min(h, h - dy)
            # source slice is from positions matching destination after shift
            shifted[sy0:sy1, sx0:sx1] = arr[dy0:dy1, dx0:dx1]
            cutouts[(row, col)] = Image.fromarray(shifted)
            print(f"  shifted ({row},{col}) by dx={dx}")
        # recompute bboxes after shift so unified bbox is tight
        for col in range(COLS):
            b = cutouts[(row, col)].getbbox()
            if b:
                bboxes.append(b)

    common = union_bbox(bboxes)
    print(f"unified bbox: {common}  size={common[2]-common[0]}x{common[3]-common[1]}")

    for (row, col), cutout in cutouts.items():
        label = ROW_LABELS[row]
        framed = cutout.crop(common)
        dest = OUT / f"{label}_{col}.png"
        framed.save(dest, "PNG")
        print(f"  saved {label}_{col}.png  {framed.size[0]}x{framed.size[1]}")

    print(f"done -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
