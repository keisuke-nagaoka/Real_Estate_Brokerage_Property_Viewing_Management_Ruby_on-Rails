"""
デモ用の物件画像(外観・室内・間取り図)を生成するスクリプト。

実在する物件の写真は使えないため、Pillow で図形を組み合わせたイラストを描いて生成する。
外観・室内は物件ごとに階数や配色を変え、間取り図は物件の間取り・専有面積から部屋の広さ(帖)を計算して描く。

実行方法(リポジトリ直下で):
  docker run --rm -v "$PWD":/work -w /work python:3.12-slim bash -c \
    "apt-get update -qq && apt-get install -y -qq fonts-noto-cjk >/dev/null && pip install -q pillow && python scripts/generate_property_images.py"
"""

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT_DIR = Path(__file__).resolve().parent.parent / "apps/naiken/backend/db/seeds/images"
W, H = 1200, 800
S = 2  # 2倍の大きさで描いてから縮小し、線をなめらかにする
FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
FONT_BOLD_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"

# db/seeds.rb の物件と同じ順番・内容(画像のファイル名の番号に対応する)
PROPERTIES = [
    ("パークハウス世田谷桜丘", "3LDK", 72.4),
    ("ブリリア杉並高井戸", "2LDK", 58.1),
    ("プラウド目黒本町", "3LDK", 75.6),
    ("ザ・パークハウス港南", "2LDK", 68.3),
    ("ライオンズ練馬中村橋", "3LDK", 65.0),
    ("シティテラス武蔵小杉", "3LDK", 70.2),
    ("クレヴィア品川大井町", "2LDK", 55.8),
    ("パークシティ日吉", "3LDK", 71.0),
    ("グランドメゾン中野", "2LDK", 60.5),
    ("コスモ三軒茶屋", "1LDK", 42.3),
    ("ルネ浦和パークサイド", "3LDK", 74.8),
    ("ザ・レジデンス船橋", "3LDK", 68.9),
    ("ブランズ横浜青葉台", "3LDK", 80.2),
]

SKIES = [
    ((96, 160, 222), (200, 228, 248)),   # 晴れ
    ((120, 180, 230), (226, 240, 250)),  # 薄曇り
    ((70, 110, 190), (250, 196, 150)),   # 夕方
    ((150, 196, 236), (236, 244, 250)),  # 朝
]
FACADES = [
    ((236, 230, 220), (150, 120, 96)),   # ベージュ + ブラウン
    ((240, 240, 238), (90, 96, 108)),    # ホワイト + チャコール
    ((206, 196, 184), (120, 84, 66)),    # グレージュ + レンガ
    ((224, 226, 230), (64, 92, 120)),    # ライトグレー + ネイビー
    ((214, 200, 178), (96, 104, 90)),    # サンド + オリーブ
]
WALLS = [(244, 239, 230), (236, 236, 232), (240, 232, 222), (232, 236, 238)]
FLOORS = [(196, 160, 118), (170, 130, 92), (214, 188, 150), (150, 112, 82)]
SOFAS = [(120, 128, 140), (60, 80, 112), (196, 160, 80), (108, 136, 112), (176, 120, 104)]


def s(v):
    return int(v * S)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(draw, box, top, bottom):
    x0, y0, x1, y1 = box
    for y in range(int(y0), int(y1)):
        draw.line([(x0, y), (x1, y)], fill=lerp(top, bottom, (y - y0) / max(1, y1 - y0)))


def finish(img, path):
    img = img.resize((W, H), Image.LANCZOS)
    img.save(path, "JPEG", quality=82, optimize=True, progressive=True)


def tree(draw, x, ground, size, rng):
    draw.rectangle([x - s(5), ground - s(size * 0.9), x + s(5), ground], fill=(110, 84, 60))
    greens = [(84, 140, 84), (102, 160, 96), (70, 124, 76)]
    for _ in range(5):
        cx = x + rng.uniform(-0.35, 0.35) * s(size)
        cy = ground - s(size) + rng.uniform(-0.3, 0.2) * s(size)
        r = s(size) * rng.uniform(0.32, 0.45)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rng.choice(greens))


def exterior(index, rng):
    img = Image.new("RGB", (s(W), s(H)))
    d = ImageDraw.Draw(img, "RGBA")
    sky_top, sky_bottom = SKIES[index % len(SKIES)]
    ground = s(H * 0.84)
    vertical_gradient(d, (0, 0, s(W), ground), sky_top, sky_bottom)

    # 雲
    for _ in range(4):
        cx, cy = rng.uniform(0.05, 0.95) * s(W), rng.uniform(0.06, 0.3) * s(H)
        for _ in range(4):
            r = rng.uniform(25, 45) * S
            ox, oy = rng.uniform(-60, 60) * S, rng.uniform(-12, 12) * S
            d.ellipse([cx + ox - r * 1.6, cy + oy - r, cx + ox + r * 1.6, cy + oy + r], fill=(255, 255, 255, 120))

    # 遠景のビル
    for _ in range(7):
        bw = rng.uniform(80, 170) * S
        bh = rng.uniform(160, 380) * S
        bx = rng.uniform(-40, W) * S
        d.rectangle([bx, ground - bh, bx + bw, ground], fill=(176, 188, 204, 170))
        for wy in range(int(ground - bh + s(14)), int(ground - s(10)), s(22)):
            for wx in range(int(bx + s(10)), int(bx + bw - s(16)), s(22)):
                d.rectangle([wx, wy, wx + s(10), wy + s(10)], fill=(214, 222, 232, 160))

    # 本体(マンション)
    facade, accent = FACADES[index % len(FACADES)]
    floors = rng.randint(7, 13)
    bays = rng.choice([4, 5, 6])
    bw = s(W * rng.uniform(0.5, 0.6))
    bx = (s(W) - bw) / 2 + rng.uniform(-60, 60) * S
    floor_h = min(s(52), (ground - s(110)) / (floors + 0.6))
    top = ground - floor_h * (floors + 0.6)
    d.rectangle([bx, top, bx + bw, ground], fill=facade)
    # アクセントの縦の壁
    accent_w = bw * 0.14
    side = rng.choice(["left", "right"])
    ax = bx if side == "left" else bx + bw - accent_w
    d.rectangle([ax, top - floor_h * 0.4, ax + accent_w, ground], fill=accent)
    d.rectangle([bx - s(6), top - s(10), bx + bw + s(6), top], fill=lerp(facade, (90, 90, 90), 0.35))

    body_x0 = bx + (accent_w if side == "left" else 0) + s(10)
    body_x1 = bx + bw - (accent_w if side == "right" else 0) - s(10)
    bay_w = (body_x1 - body_x0) / bays
    for f in range(floors):
        fy = ground - floor_h * (f + 1.6)
        if f == 0:
            continue
        for b in range(bays):
            wx0 = body_x0 + b * bay_w + s(8)
            wx1 = body_x0 + (b + 1) * bay_w - s(8)
            # 窓(ガラス)
            glass_top, glass_bottom = (70, 104, 140), (120, 156, 186)
            for y in range(int(fy + s(6)), int(fy + floor_h - s(8))):
                t = (y - fy) / floor_h
                d.line([(wx0, y), (wx1, y)], fill=lerp(glass_top, glass_bottom, t))
            # 映り込み
            d.polygon([(wx0 + (wx1 - wx0) * 0.55, fy + s(6)), (wx0 + (wx1 - wx0) * 0.75, fy + s(6)),
                       (wx0 + (wx1 - wx0) * 0.45, fy + floor_h - s(8)), (wx0 + (wx1 - wx0) * 0.25, fy + floor_h - s(8))],
                      fill=(255, 255, 255, 40))
        # バルコニーの床と手すり(すりガラス)
        d.rectangle([body_x0 - s(6), fy + floor_h - s(8), body_x1 + s(6), fy + floor_h], fill=lerp(facade, (255, 255, 255), 0.5))
        d.rectangle([body_x0 - s(6), fy + floor_h * 0.52, body_x1 + s(6), fy + floor_h - s(8)], fill=(214, 228, 236, 150))
        d.line([(body_x0 - s(6), fy + floor_h * 0.52), (body_x1 + s(6), fy + floor_h * 0.52)], fill=(160, 170, 180), width=s(2))
        for b in range(bays + 1):
            px = body_x0 + b * bay_w
            d.rectangle([px - s(3), fy, px + s(3), fy + floor_h], fill=lerp(facade, (120, 120, 120), 0.15))

    # エントランス
    ex = bx + bw * (0.55 if side == "left" else 0.25)
    d.rectangle([ex - s(30), top + (ground - top) - floor_h * 1.1 - s(10), ex + bw * 0.25, ground - floor_h * 1.1], fill=accent)
    d.rectangle([ex, ground - floor_h * 1.1, ex + bw * 0.2, ground], fill=(150, 184, 204))
    d.line([(ex + bw * 0.1, ground - floor_h * 1.1), (ex + bw * 0.1, ground)], fill=(110, 130, 140), width=s(3))
    d.rectangle([bx + s(10), ground - floor_h * 1.1, ex - s(40), ground], fill=lerp(facade, (0, 0, 0), 0.08))

    # 地面・植栽
    d.rectangle([0, ground, s(W), s(H)], fill=(196, 196, 190))
    d.rectangle([0, ground + s(32), s(W), s(H)], fill=(150, 150, 146))
    d.rectangle([0, ground - s(6), s(W), ground + s(14)], fill=(118, 168, 98))
    for x in [rng.uniform(0.02, 0.18), rng.uniform(0.82, 0.97), rng.uniform(0.2, 0.3)]:
        tree(d, s(W * x), ground + s(10), rng.uniform(70, 120), rng)
    for _ in range(12):
        sx = rng.uniform(0, W) * S
        d.ellipse([sx - s(22), ground - s(16), sx + s(22), ground + s(14)], fill=(92, 146, 86))

    return img


def interior(index, rng):
    img = Image.new("RGB", (s(W), s(H)))
    d = ImageDraw.Draw(img, "RGBA")
    wall = WALLS[index % len(WALLS)]
    floor = FLOORS[index % len(FLOORS)]
    horizon = s(H * 0.7)
    d.rectangle([0, 0, s(W), horizon], fill=wall)
    # 天井の影
    vertical_gradient(d, (0, 0, s(W), s(70)), lerp(wall, (0, 0, 0), 0.08), wall)

    # 床(フローリング)
    d.rectangle([0, horizon, s(W), s(H)], fill=floor)
    plank_h = s(26)
    for i, y in enumerate(range(horizon, s(H), plank_h)):
        d.line([(0, y), (s(W), y)], fill=lerp(floor, (0, 0, 0), 0.12), width=s(1))
        offset = (i * 137) % 300
        for x in range(-offset * S, s(W), s(300)):
            d.line([(x, y), (x, y + plank_h)], fill=lerp(floor, (0, 0, 0), 0.1), width=s(1))
    d.rectangle([0, horizon - s(10), s(W), horizon], fill=lerp(wall, (0, 0, 0), 0.15))

    # 窓
    wx0, wx1 = s(W * 0.52), s(W * 0.94)
    wy0, wy1 = s(H * 0.12), horizon - s(12)
    sky_top, sky_bottom = SKIES[index % len(SKIES)]
    vertical_gradient(d, (wx0, wy0, wx1, wy1), sky_top, sky_bottom)
    for _ in range(6):
        bw, bh = rng.uniform(40, 90) * S, rng.uniform(60, 200) * S
        bx = rng.uniform(wx0, wx1 - bw)
        d.rectangle([bx, wy1 - bh, bx + bw, wy1], fill=(190, 200, 214, 200))
    d.rectangle([wx0, wy1 - s(70), wx1, wy1], fill=(220, 232, 238, 110))  # バルコニーの手すり
    for x in [wx0, (wx0 + wx1) / 2, wx1]:
        d.rectangle([x - s(5), wy0, x + s(5), wy1], fill=(248, 248, 246))
    d.rectangle([wx0 - s(5), wy0 - s(6), wx1 + s(5), wy0 + s(4)], fill=(248, 248, 246))
    # カーテン
    curtain = lerp(wall, (255, 255, 255), 0.4)
    for cx in [wx0 - s(46), wx1 - s(6)]:
        d.rectangle([cx, wy0 - s(10), cx + s(52), horizon - s(14)], fill=curtain)
        for k in range(1, 4):
            d.line([(cx + k * s(13), wy0 - s(10)), (cx + k * s(13), horizon - s(14))], fill=lerp(curtain, (0, 0, 0), 0.07), width=s(2))

    # 壁の絵
    ax0, ay0 = s(W * 0.12), s(H * 0.17)
    d.rectangle([ax0, ay0, ax0 + s(170), ay0 + s(120)], fill=(255, 255, 255), outline=(80, 70, 60), width=s(4))
    art = [(214, 150, 120), (120, 150, 190), (220, 190, 120)]
    d.ellipse([ax0 + s(25), ay0 + s(25), ax0 + s(95), ay0 + s(95)], fill=art[index % 3])
    d.rectangle([ax0 + s(80), ay0 + s(50), ax0 + s(145), ay0 + s(100)], fill=art[(index + 1) % 3])

    # ペンダントライト
    lx = s(W * 0.3)
    d.line([(lx, 0), (lx, s(150))], fill=(60, 60, 60), width=s(2))
    d.polygon([(lx - s(40), s(190)), (lx + s(40), s(190)), (lx + s(18), s(150)), (lx - s(18), s(150))], fill=(60, 60, 64))
    d.ellipse([lx - s(60), s(185), lx + s(60), s(215)], fill=(255, 236, 180, 70))

    # ラグ・ソファ・テーブル
    d.ellipse([s(W * 0.08), s(H * 0.78), s(W * 0.62), s(H * 0.96)], fill=lerp(floor, (240, 236, 228), 0.75))
    sofa = SOFAS[index % len(SOFAS)]
    sx0, sx1 = s(W * 0.06), s(W * 0.5)
    sy = s(H * 0.6)
    d.rounded_rectangle([sx0, sy - s(90), sx1, sy + s(20)], radius=s(18), fill=lerp(sofa, (0, 0, 0), 0.08))
    d.rounded_rectangle([sx0 - s(14), sy - s(20), sx1 + s(14), sy + s(70)], radius=s(16), fill=sofa)
    for k in range(3):
        cx0 = sx0 + s(14) + k * (sx1 - sx0 - s(28)) / 3
        d.rounded_rectangle([cx0 + s(4), sy - s(30), cx0 + (sx1 - sx0 - s(28)) / 3 - s(4), sy + s(10)], radius=s(10), fill=lerp(sofa, (255, 255, 255), 0.12))
    d.rounded_rectangle([sx0 + s(30), sy - s(70), sx0 + s(110), sy - s(20)], radius=s(12), fill=(236, 226, 206))
    for lx2 in [sx0, sx1 - s(10)]:
        d.rectangle([lx2, sy + s(70), lx2 + s(10), sy + s(90)], fill=(70, 56, 44))
    tx0, tx1, ty = s(W * 0.2), s(W * 0.42), s(H * 0.86)
    d.rounded_rectangle([tx0, ty - s(16), tx1, ty], radius=s(6), fill=(120, 86, 60))
    for lx2 in [tx0 + s(14), tx1 - s(22)]:
        d.rectangle([lx2, ty, lx2 + s(8), ty + s(36)], fill=(90, 64, 46))
    d.ellipse([tx0 + s(40), ty - s(36), tx0 + s(80), ty - s(14)], fill=(250, 250, 248))

    # 観葉植物
    px = s(W * 0.44)
    py = horizon + s(40)
    d.polygon([(px - s(34), py - s(70)), (px + s(34), py - s(70)), (px + s(24), py), (px - s(24), py)], fill=(222, 214, 204))
    for _ in range(14):
        ang = rng.uniform(-math.pi * 0.95, -math.pi * 0.05)
        length = rng.uniform(70, 150) * S
        ex, ey = px + math.cos(ang) * length, py - s(70) + math.sin(ang) * length
        d.line([(px, py - s(70)), (ex, ey)], fill=(70, 120, 76), width=s(3))
        d.ellipse([ex - s(20), ey - s(11), ex + s(20), ey + s(11)], fill=rng.choice([(76, 138, 84), (96, 156, 96)]))

    return img.filter(ImageFilter.SMOOTH_MORE)


def floor_plan(name, layout, area):
    img = Image.new("RGB", (s(W), s(H)), (255, 255, 255))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_PATH, s(20))
    font_room = ImageFont.truetype(FONT_BOLD_PATH, s(22))
    font_title = ImageFont.truetype(FONT_BOLD_PATH, s(30))

    d.text((s(60), s(40)), f"{layout}  専有面積 {area}㎡", font=font_title, fill=(40, 40, 48))
    d.text((s(60), s(86)), name, font=font, fill=(110, 110, 120))

    # 方位記号
    cx, cy = s(W - 90), s(80)
    d.ellipse([cx - s(30), cy - s(30), cx + s(30), cy + s(30)], outline=(120, 120, 130), width=s(2))
    d.polygon([(cx, cy - s(26)), (cx - s(10), cy + s(8)), (cx + s(10), cy + s(8))], fill=(200, 80, 70))
    d.text((cx - s(7), cy + s(30)), "N", font=font, fill=(120, 120, 130))

    bedrooms = int(layout[0])
    x0, x1 = s(140), s(W - 140)
    y0, y1 = s(150), s(H - 150)
    balcony_y = y1 + s(10)

    # 面積の配分(LDKを大きめに、残りを洋室・水回りに割り当てる)
    ldk_ratio = 0.42 if bedrooms >= 3 else 0.48 if bedrooms == 2 else 0.55
    bed_ratio = (1 - ldk_ratio - 0.2) / bedrooms
    jo = lambda ratio: f"{area * ratio / 1.62:.1f}帖"  # 1帖 ≒ 1.62㎡

    top_h = (y1 - y0) * 0.44
    right_w = (x1 - x0) * 0.26
    rooms = []
    bw = (x1 - x0) / bedrooms
    if bedrooms == 1:
        # 1LDK は洋室の横にウォークインクローゼットを置く
        split = x0 + (x1 - x0) * 0.68
        rooms.append(((x0, y0, split, y0 + top_h), "洋室", jo(bed_ratio * 0.75), (250, 244, 232)))
        rooms.append(((split, y0, x1, y0 + top_h), "WIC", "", (244, 240, 232)))
    else:
        for i in range(bedrooms):
            rooms.append(((x0 + bw * i, y0, x0 + bw * (i + 1), y0 + top_h), f"洋室{i + 1}", jo(bed_ratio), (250, 244, 232)))
    rooms.append(((x0, y0 + top_h, x1 - right_w, y1), "LDK", jo(ldk_ratio), (246, 236, 214)))
    wet_h = (y1 - y0 - top_h) / 4
    wet = [("浴室", (226, 240, 248)), ("洗面室", (232, 242, 248)), ("トイレ", (232, 242, 248)), ("玄関", (236, 236, 236))]
    for i, (label, color) in enumerate(wet):
        top = y0 + top_h + wet_h * i
        rooms.append(((x1 - right_w, top, x1, top + wet_h), label, "", color))

    for (rx0, ry0, rx1, ry1), label, size, color in rooms:
        d.rectangle([rx0, ry0, rx1, ry1], fill=color, outline=(70, 70, 76), width=s(5))
        cx, cy = (rx0 + rx1) / 2, (ry0 + ry1) / 2
        f = font_room if label in ("LDK",) or label.startswith("洋室") else font
        tw = d.textlength(label, font=f)
        d.text((cx - tw / 2, cy - s(22 if size else 12)), label, font=f, fill=(50, 50, 58))
        if size:
            sw = d.textlength(size, font=font)
            d.text((cx - sw / 2, cy + s(8)), size, font=font, fill=(90, 90, 100))
        # ドア(開き戸の弧)
        door = s(34)
        if ry1 <= y0 + top_h + 1 and label.startswith("洋室"):
            d.arc([rx0 + s(20), ry1 - door, rx0 + s(20) + door * 2, ry1 + door], 180, 270, fill=(110, 110, 120), width=s(2))

    # キッチン
    lx1 = x1 - right_w
    d.rectangle([lx1 - s(56), y0 + top_h + s(30), lx1 - s(14), y1 - s(40)], fill=(255, 255, 255), outline=(110, 110, 120), width=s(3))
    d.text((lx1 - s(46), y0 + top_h + s(40)), "K", font=font, fill=(110, 110, 120))
    # 浴槽(部屋名と重ならないよう左側に寄せる)
    bx0, by0 = x1 - right_w + s(14), y0 + top_h + s(12)
    d.rounded_rectangle([bx0, by0, bx0 + right_w * 0.3, by0 + wet_h - s(24)], radius=s(10), outline=(140, 160, 176), width=s(3))

    # バルコニー
    d.rectangle([x0, balcony_y, x1 - right_w, balcony_y + s(70)], outline=(120, 120, 130), width=s(3))
    # 斜線は枠からはみ出さないよう、右端で切る
    hatch_end = x1 - right_w
    for hx in range(int(x0), int(hatch_end), s(24)):
        dx = min(s(30), hatch_end - hx)
        d.line([(hx, balcony_y + s(70)), (hx + dx, balcony_y + s(70) - s(70) * dx / s(30))], fill=(200, 200, 206), width=s(2))
    label = "バルコニー"
    d.rectangle([(x0 + x1 - right_w) / 2 - s(70), balcony_y + s(20), (x0 + x1 - right_w) / 2 + s(70), balcony_y + s(52)], fill=(255, 255, 255))
    d.text(((x0 + x1 - right_w) / 2 - d.textlength(label, font=font) / 2, balcony_y + s(20)), label, font=font, fill=(90, 90, 100))

    d.text((s(60), s(H - 60)), "※ デモ用に自動生成した間取り図です", font=font, fill=(150, 150, 160))
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for i, (name, layout, area) in enumerate(PROPERTIES, start=1):
        rng = random.Random(i)  # 物件ごとに固定の乱数で、何度実行しても同じ画像にする
        finish(exterior(i - 1, rng), OUT_DIR / f"property-{i:02d}-1-exterior.jpg")
        finish(interior(i - 1, rng), OUT_DIR / f"property-{i:02d}-2-interior.jpg")
        finish(floor_plan(name, layout, area), OUT_DIR / f"property-{i:02d}-3-floorplan.jpg")
        print(f"generated: {i:02d} {name}")


if __name__ == "__main__":
    main()
