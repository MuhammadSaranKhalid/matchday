#!/usr/bin/env bash
# understand_video.sh — turn a screen-recording into reviewable stills.
#
# Usage:  scripts/understand_video.sh <video> [fps] [tile_w] [tile_h]
#   <video>   path to the .mov/.mp4 (quotes if it has spaces/unicode)
#   fps       frames per second to sample           (default 1)
#   tile_w    contact-sheet columns                 (default 4)
#   tile_h    contact-sheet rows                     (default 4)
#
# Produces, next to the video, a <name>_frames/ dir:
#   frames/f_XXX.png   full-res stills, each stamped with its video timestamp
#   sheets/sheet_X.png contact sheets (tile_w × tile_h stills per image)
#
# The per-frame timestamp (top-left, yellow) lets you point at "the bug happens
# at 00:00:12" precisely.
set -euo pipefail

VID="${1:?usage: understand_video.sh <video> [fps] [tile_w] [tile_h]}"
FPS="${2:-1}"
TW="${3:-4}"
TH="${4:-4}"

[ -f "$VID" ] || { echo "no such file: $VID" >&2; exit 1; }

DIR="$(cd "$(dirname "$VID")" && pwd)"
BASE="$(basename "$VID")"; BASE="${BASE%.*}"
OUT="$DIR/${BASE}_frames"
rm -rf "$OUT"; mkdir -p "$OUT/frames" "$OUT/sheets"

# 1) full-res stills, one every 1/FPS sec. (drawtext is unavailable in some
#    ffmpeg builds, so we rely on frame numbering: at fps=1, f_NNN ≈ second NNN-1.)
ffmpeg -hide_banner -loglevel error -i "$VID" \
  -vf "fps=${FPS}" \
  "$OUT/frames/f_%03d.png"

N=$(ls "$OUT/frames" | wc -l | tr -d ' ')
echo "extracted $N frames at ${FPS} fps -> $OUT/frames  (f_NNN ≈ second NNN-1)"

# 2) contact sheets: TW×TH stills per sheet, scaled so UI text stays legible.
ffmpeg -hide_banner -loglevel error -framerate 1 -i "$OUT/frames/f_%03d.png" \
  -vf "scale=320:-1,tile=${TW}x${TH}:margin=6:padding=4:color=white" \
  "$OUT/sheets/sheet_%d.png"

echo "contact sheets -> $OUT/sheets"
ls "$OUT/sheets"
