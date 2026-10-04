#!/usr/bin/env bash
# ============================================================
# 物业管理系统 — 小筑「宠物」派生图标生成器
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================
# 用法: bash scripts/gen-pet-icons.sh
#   从唯一真源 docs/images/favicon.svg 生成全仓 50+ 件派生位图：
#   Flutter 管理端壳层（Android / iOS / macOS / Windows / web + 启动图）、
#   Flutter 业主端 web、两端 HarmonyOS（app_icon / start_icon / rawfile）、
#   后端 favicon.ico（admin + service）。
#
#   三个变体（真源是「64 画布 + 内缩圆角瓦片」，平台图标不能直接用原样）：
#     tile     原样渲染（自带圆角 + 透明边距）→ 浏览器 / 桌面 / 启动图 / rawfile
#     full     viewBox 裁到瓦片 + rx=0 满铺且去 alpha → iOS / Android / HarmonyOS 应用图标
#     maskable tile 缩 80% 居中 + 靛蓝实底 → web maskable 两件（中央 80% 安全区）
#
#   真源 md5 守卫：favicon.svg 改动后必须同步更新 EXPECT_MD5 再重跑。
# 依赖: rsvg-convert (librsvg) + ImageMagick 7（magick）。
# 幂等: 全量重写目标文件，可重复执行；末行打印全部产物的 md5 锚点。
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/docs/images/favicon.svg"
EXPECT_MD5="6f1fc0441d483b6725e8d72cdb86f980"   # 头肩标记（docs/images/favicon.svg）

ACTUAL="$(md5sum "$SRC" | cut -d' ' -f1)"
if [ "$ACTUAL" != "$EXPECT_MD5" ]; then
  echo "✗ 真源 md5 已变：$ACTUAL（期望 $EXPECT_MD5）——核对改动后更新脚本常量再重跑" >&2
  exit 1
fi

fail() { echo "✗ $*" >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
TILE="$TMP/tile.svg"; FULL="$TMP/full.svg"
cp "$SRC" "$TILE"
# full: 裁到瓦片本身（x/y=2 边长 60）并去掉圆角 → 满铺、不透明
sed -e 's|viewBox="0 0 64 64"|viewBox="2 2 60 60"|' \
    -e 's|rx="15" fill="url(#fvTile)"|rx="0" fill="url(#fvTile)"|' "$SRC" > "$FULL"

OUTS=()
R() { rsvg-convert -w "$1" -h "$1" "$2" -o "$3"; }                        # 方图渲染
T() { R "$1" "$TILE" "$2"; OUTS+=("$2"); }                                # tile 变体
# full 变体：去 alpha + 去 date:* 元数据（ImageMagick 默认写 date:create/modify/timestamp
# 三个 tEXt 块，导致同内容两次生成的 md5 因秒差而不同，破坏字节互认）
F() { R "$1" "$FULL" "$2"; magick "$2" -alpha off +set date:create +set date:modify +set date:timestamp "$2"; OUTS+=("$2"); }
STRIP_DATES=(+set date:create +set date:modify +set date:timestamp)

AF="$ROOT/admin/apps/flutter"; OF="$ROOT/apps/flutter"
AH="$ROOT/admin/apps/harmonyos"; OH="$ROOT/apps/harmonyos"

# ① Android launcher（full，5 档 legacy mipmap）
for x in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  F "${x##*:}" "$AF/android/app/src/main/res/mipmap-${x%%:*}/ic_launcher.png"
done

# ② iOS AppIcon（full，15 件；文件名 ↔ 像素硬绑定，与 Contents.json 对应）
I="$AF/ios/Runner/Assets.xcassets/AppIcon.appiconset"
F 20 "$I/Icon-App-20x20@1x.png";      F 40 "$I/Icon-App-20x20@2x.png";       F 60 "$I/Icon-App-20x20@3x.png"
F 29 "$I/Icon-App-29x29@1x.png";      F 58 "$I/Icon-App-29x29@2x.png";       F 87 "$I/Icon-App-29x29@3x.png"
F 40 "$I/Icon-App-40x40@1x.png";      F 80 "$I/Icon-App-40x40@2x.png";       F 120 "$I/Icon-App-40x40@3x.png"
F 120 "$I/Icon-App-60x60@2x.png";     F 180 "$I/Icon-App-60x60@3x.png"
F 76 "$I/Icon-App-76x76@1x.png";      F 152 "$I/Icon-App-76x76@2x.png"
F 167 "$I/Icon-App-83.5x83.5@2x.png"; F 1024 "$I/Icon-App-1024x1024@1x.png"

# ③ macOS（tile，7 件；不套遮罩，保留圆角才是 HIG 正确形态）
M="$AF/macos/Runner/Assets.xcassets/AppIcon.appiconset"
for s in 16 32 64 128 256 512 1024; do T "$s" "$M/app_icon_$s.png"; done

# ④ Windows ico（tile 多帧）
for s in 16 24 32 48 64 128 256; do R "$s" "$TILE" "$TMP/tile-$s.png"; done
magick "$TMP"/tile-16.png "$TMP"/tile-24.png "$TMP"/tile-32.png "$TMP"/tile-48.png \
       "$TMP"/tile-64.png "$TMP"/tile-128.png "$TMP"/tile-256.png "$AF/windows/runner/resources/app_icon.ico"
OUTS+=("$AF/windows/runner/resources/app_icon.ico")

# ⑤ 两端 web（tile + maskable + favicon.png 提到 32px）
for W in "$AF/web" "$OF/web"; do
  T 192 "$W/icons/Icon-192.png"
  T 512 "$W/icons/Icon-512.png"
  T 32  "$W/favicon.png"
  R 192 "$TILE" "$TMP/mask192.png"
  R 512 "$TILE" "$TMP/mask512.png"
  magick "$TMP/mask192.png" -resize 80% -background '#4F46E5' -gravity center -extent 192x192 "${STRIP_DATES[@]}" "$W/icons/Icon-maskable-192.png"
  magick "$TMP/mask512.png" -resize 80% -background '#4F46E5' -gravity center -extent 512x512 "${STRIP_DATES[@]}" "$W/icons/Icon-maskable-512.png"
  OUTS+=("$W/icons/Icon-maskable-192.png" "$W/icons/Icon-maskable-512.png")
done

# ⑥ 启动图（Android 5 档 + iOS 3 件；iOS 由 LaunchScreen.storyboard 指向 imageset 生效）
for x in mdpi:120 hdpi:180 xhdpi:240 xxhdpi:360 xxxhdpi:480; do
  T "${x##*:}" "$AF/android/app/src/main/res/mipmap-${x%%:*}/launch_image.png"
done
L="$AF/ios/Runner/Assets.xcassets/LaunchImage.imageset"
T 168 "$L/LaunchImage.png"; T 336 "$L/LaunchImage@2x.png"; T 504 "$L/LaunchImage@3x.png"

# ⑦ HarmonyOS 两端（应用图标 216 full；start_icon / rawfile 均 tile）
F 216 "$AH/AppScope/resources/base/media/app_icon.png"
F 216 "$AH/entry/src/main/resources/base/media/app_icon.png"
F 216 "$OH/AppScope/resources/base/media/app_icon.png"
F 216 "$OH/entry/src/main/resources/base/media/app_icon.png"
T 128 "$AH/entry/src/main/resources/base/media/start_icon.png"
T 128 "$OH/entry/src/main/resources/base/media/start_icon.png"   # owner 侧为死资源，一并换求一致
T 128 "$AH/entry/src/main/resources/rawfile/logo.png"            # 登录页 64dp 位
T 240 "$AH/entry/src/main/resources/rawfile/empty.png"            # EmptyView 120dp 位的 2×
mkdir -p "$OH/entry/src/main/resources/rawfile"                   # owner 侧本次新建
T 128 "$OH/entry/src/main/resources/rawfile/logo.png"

# ⑧ 后端 favicon.ico（tile 16/32/48 多帧；service 与 admin 同一份）
for s in 16 32 48; do R "$s" "$TILE" "$TMP/ico-$s.png"; done
magick "$TMP/ico-16.png" "$TMP/ico-32.png" "$TMP/ico-48.png" "$ROOT/admin/public/favicon.ico"
cp "$ROOT/admin/public/favicon.ico" "$ROOT/service/public/favicon.ico"
OUTS+=("$ROOT/admin/public/favicon.ico" "$ROOT/service/public/favicon.ico")

# ⑨ Android adaptive icon 前景（anydpi-v26：背景纯靛蓝，前景=满铺瓦片缩到 66.7% 安全区，
#     圆形遮罩裁出的正是瓦片中心的小筑；XML 见 mipmap-anydpi-v26/ic_launcher.xml 与 values/）
for x in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  d="${x%%:*}"; n="${x##*:}"; fg=$(( n * 2 / 3 ))
  R "$fg" "$FULL" "$TMP/fg-$n.png"
  magick "$TMP/fg-$n.png" -background none -gravity center -extent "${n}x${n}" "${STRIP_DATES[@]}" \
    "$AF/android/app/src/main/res/mipmap-$d/ic_launcher_foreground.png"
  OUTS+=("$AF/android/app/src/main/res/mipmap-$d/ic_launcher_foreground.png")
done

# ⑩ og 分享卡 1200×630（README/站点社交预览；思源黑体，缺失即中止）
FONT="$(fc-list :lang=zh -f '%{file}\n' 2>/dev/null | grep -i 'SourceHanSansCN-Regular' | head -1 || true)"
[ -n "$FONT" ] || FONT="$(fc-list :lang=zh -f '%{file}\n' 2>/dev/null | head -1 || true)"
[ -n "$FONT" ] || fail "无中文字体（fc-list :lang=zh 为空），og 卡无法生成"
R 140 "$TILE" "$TMP/og-mark.png"
# 全身像用 rsvg 预渲染（IM 内置 SVG 渲染器不认渐变/透明，会画出白块）
rsvg-convert -h 500 "$ROOT/docs/images/pet_xiaozhu.svg" -o "$TMP/og-pet.png"
magick -size 1200x630 "gradient:#6366F1-#4338CA" \
  "$TMP/og-mark.png" -geometry +80+80 -composite \
  "$TMP/og-pet.png" -gravity southeast -geometry +80+24 -composite \
  -gravity northwest -font "$FONT" -fill white -pointsize 64 -annotate +80+300 '物业管理平台' \
  -fill '#E0E7FF' -pointsize 30 -annotate +84+372 '小筑 · 楼宇管家' \
  "${STRIP_DATES[@]}" "$ROOT/docs/images/og_card.png"
OUTS+=("$ROOT/docs/images/og_card.png")
for d in "$AF/web" "$OF/web" "$ROOT/admin/public" "$ROOT/service/public"; do
  cp "$ROOT/docs/images/og_card.png" "$d/og_card.png"; OUTS+=("$d/og_card.png")
done

# ⑪ 后端 PDF 品牌位（dompdf 不渲染 SVG，用 128px PNG 由 ExportController base64 内嵌）
T 128 "$ROOT/admin/public/pet_mark_128.png"

# ---- 校验 ----
# %[channels] 值形如 "srgb 3.0" / "srgba 4.0" —— 必须以 "srgb " 开头（排除 srgba）。
# 注：小尺寸位图 IM 会做调色板优化，报 "srgb 4.0"（索引通道被计为 channel），
# 但 IHDR colorType=palette 且无 tRNS ⇒ 实际无 alpha，属通过（verifier 2026-10-03 复核确认）。
no_alpha() { identify -format '%[channels]' "$1" | grep -q '^srgb ' || fail "含 alpha：$1（$(identify -format '%[channels]' "$1")）"; }
size() { [ "$(identify -format '%wx%h' "$1")" = "$2x$2" ] || fail "尺寸错：$1（期望 ${2}²）"; }

for f in "$I"/*.png "$AF"/android/app/src/main/res/mipmap-*/ic_launcher.png \
         "$AH/AppScope/resources/base/media/app_icon.png" "$AH/entry/src/main/resources/base/media/app_icon.png" \
         "$OH/AppScope/resources/base/media/app_icon.png" "$OH/entry/src/main/resources/base/media/app_icon.png"; do
  no_alpha "$f"
done
size "$I/Icon-App-1024x1024@1x.png" 1024
size "$OH/AppScope/resources/base/media/app_icon.png" 216
size "$AF/web/favicon.png" 32
size "$AF/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png" 432
size "$ROOT/admin/public/pet_mark_128.png" 128
[ "$(identify -format '%wx%h' "$ROOT/docs/images/og_card.png")" = "1200x630" ] || fail "og_card 尺寸错"
[ "$(magick identify "$AF/windows/runner/resources/app_icon.ico" | wc -l)" -eq 7 ] || fail "Windows ico 帧数不对"
[ "$(magick identify "$ROOT/admin/public/favicon.ico" | wc -l)" -eq 3 ] || fail "favicon.ico 帧数不对"

# ---- 锚点 ----
echo "✓ 生成 ${#OUTS[@]} 件产物（PNG + ico）"
echo "--- md5 锚点 ---"
md5sum "${OUTS[@]}" | sed "s|$ROOT/||"
