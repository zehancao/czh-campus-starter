#!/usr/bin/env python3
"""
为校园助手所有商品生成品牌化占位图
- 按分类自动匹配阳光配色渐变背景
- 大号 emoji 图标
- 商品名称 + 价格
- 输出 SQL 更新语句
"""

import re
import os
import math
import uuid
import json
from PIL import Image, ImageDraw, ImageFont

# ═══════════════════════════════════════
# 路径配置
# ═══════════════════════════════════════
SQL_FILE = "/Users/caozehan/Desktop/czh-campus-starter/campusdb2.sql"
UPLOADS_DIR = "/Users/caozehan/Desktop/czh-campus-starter/Campus-Server/uploads"
SQL_OUTPUT = "/Users/caozehan/Desktop/czh-campus-starter/generated-designs/product_images_update.sql"
IMG_SIZE = 600

# ═══════════════════════════════════════
# 分类 → 渐变色 + emoji 映射
# ═══════════════════════════════════════
CATEGORY_CONFIG = {
    1:  {"name": "教材", "gradient": [(255, 140, 66), (255, 107, 44)],  "emoji": "📚", "label": "书"},
    2:  {"name": "公共课", "gradient": [(255, 140, 66), (255, 107, 44)],  "emoji": "📖", "label": "课"},
    3:  {"name": "专业课", "gradient": [(255, 140, 66), (255, 107, 44)],  "emoji": "📕", "label": "业"},
    4:  {"name": "考研", "gradient": [(255, 210, 63), (255, 182, 39)],   "emoji": "✏️", "label": "考"},
    5:  {"name": "电子", "gradient": [(6, 174, 213), (2, 136, 209)],     "emoji": "📱", "label": "电"},
    6:  {"name": "手机", "gradient": [(6, 174, 213), (2, 136, 209)],     "emoji": "📱", "label": "机"},
    7:  {"name": "电脑", "gradient": [(6, 174, 213), (2, 136, 209)],     "emoji": "💻", "label": "脑"},
    8:  {"name": "耳机", "gradient": [(6, 174, 213), (2, 136, 209)],     "emoji": "🎧", "label": "听"},
    9:  {"name": "数码", "gradient": [(6, 174, 213), (2, 136, 209)],     "emoji": "🔌", "label": "码"},
    10: {"name": "生活", "gradient": [(255, 210, 63), (255, 182, 39)],   "emoji": "🏠", "label": "活"},
    11: {"name": "宿舍", "gradient": [(255, 210, 63), (255, 182, 39)],   "emoji": "🛏️", "label": "宿"},
    12: {"name": "收纳", "gradient": [(255, 210, 63), (255, 182, 39)],   "emoji": "📦", "label": "纳"},
    13: {"name": "个护", "gradient": [(236, 72, 153), (219, 39, 119)],   "emoji": "🧴", "label": "护"},
    14: {"name": "运动", "gradient": [(16, 185, 129), (5, 150, 105)],    "emoji": "⚽", "label": "动"},
    15: {"name": "球类", "gradient": [(16, 185, 129), (5, 150, 105)],    "emoji": "🏀", "label": "球"},
    16: {"name": "骑行", "gradient": [(16, 185, 129), (5, 150, 105)],    "emoji": "🚲", "label": "骑"},
    17: {"name": "户外", "gradient": [(16, 185, 129), (5, 150, 105)],    "emoji": "🏕️", "label": "野"},
    18: {"name": "其他", "gradient": [(139, 149, 168), (107, 114, 128)], "emoji": "🎁", "label": "他"},
    19: {"name": "免费", "gradient": [(16, 185, 129), (5, 150, 105)],    "emoji": "🎁", "label": "免"},
}

# 关键词 → emoji 精细匹配（覆盖在分类默认 emoji 上）
KEYWORD_EMOJI = {
    "高数": "📐", "数学": "📐", "线代": "📐", "概率": "📐", "复变": "📐", "数分": "📐",
    "物理": "🔭", "化学": "🧪", "英语": "🔤", "语文": "📝", "思政": "📑", "毛概": "📑",
    "马原": "📑", "史纲": "📜", "军事": "🎖️", "形策": "📋",
    "数据结构": "💾", "计算机网络": "🌐", "操作系统": "🖥️", "编译": "⚙️", "数据库": "🗄️",
    "飞行": "✈️", "航空": "✈️", "空管": "🛫", "安全": "🛡️", "交通": "🚦",
    "考研": "🎓", "考公": "🎓", "行测": "📝", "申论": "📝", "面试": "💬",
    "iPhone": "📱", "华为": "📱", "小米": "📱", "三星": "📱", "OPPO": "📱", "vivo": "📱", "Redmi": "📱",
    "iPad": "📋", "平板": "📋",
    "MacBook": "💻", "联想": "💻", "机械革命": "💻", "MateBook": "💻", "笔记本": "💻",
    "显示器": "🖥️", "键盘": "⌨️", "鼠标": "🖱️", "固态": "💽", "SSD": "💽", "内存": "💾", "DDR": "💾",
    "AirPods": "🎧", "耳机": "🎧", "索尼": "🎧", "华为FreeBuds": "🎧", "Bose": "🎧", "铁三角": "🎧",
    "音箱": "🔊", "JBL": "🔊", "漫步者": "🔊",
    "手环": "⌚", "手表": "⌚", "Apple Watch": "⌚",
    "充电宝": "🔋", "充电器": "🔌", "Anker": "🔌",
    "Kindle": "📖", "树莓派": "🍓", "Switch": "🎮", "无人机": "🚁", "GoPro": "📷", "相机": "📷", "微单": "📷",
    "路由器": "📡", "扩展坞": "🔗", "数位板": "✏️", "摄像头": "📹", "硬盘": "💾", "智能音箱": "🔊",
    "保温杯": "🥤", "水壶": "🫖", "台灯": "💡", "雨伞": "☂️", "风扇": "🌀", "毛巾": "🧖",
    "订书机": "📎", "收纳袋": "👜",
    "床帘": "🛏️", "挂篮": "🧺", "推车": "🛒", "衣架": "👔", "夜灯": "💡", "挂钩": "🪝",
    "脏衣篓": "🧺", "书架": "📚", "拖鞋": "👟", "蚊帐": "🛡️",
    "书桌": "🪑", "椅子": "🪑", "收纳箱": "📦", "收纳盒": "📦", "分隔板": "🗂️", "置物架": "🗄️", "边几": "🪑", "收纳柜": "🗄️",
    "洗面奶": "🧴", "防晒": "🧴", "润唇膏": "💄", "洗护": "🧴", "牙刷": "🪥", "面膜": "🎭", "退热贴": "💊",
    "梳子": "💅", "卸妆": "🧴", "爽肤水": "💧",
    "跑鞋": "👟", "瑜伽垫": "🧘", "跳绳": "🏃", "蛋白粉": "💪", "手套": "🧤", "速干": "👕", "水壶": "🥤",
    "泡沫轴": "🧘", "护膝": "🦵", "乒乓球": "🏓", "篮球": "🏀", "足球": "⚽", "羽毛球": "🏸",
    "排球": "🏐", "哑铃": "🏋️", "弹力带": "💪", "网球": "🎾", "臂力器": "💪", "俯卧撑": "💪", "拉力器": "💪",
    "山地车": "🚵", "死飞": "🚲", "滑板": "🛹", "头盔": "⛑️", "折叠车": "🚲", "长板": "🛹", "电动车": "🛵",
    "双肩包": "🎒", "帐篷": "⛺", "睡袋": "🛌", "登山杖": "🥾", "炉头": "🔥", "冲锋衣": "🧥", "速干裤": "👖",
    "防潮垫": "🟫", "头灯": "🔦", "水袋": "💧",
    "吉他": "🎸", "尤克里里": "🎵", "素描": "🎨", "拼图": "🧩", "UNO": "🃏", "象棋": "♟️", "日语": "🇯🇵",
    "拨片": "🎵", "口琴": "🎵",
    "绿萝": "🪴", "盆栽": "🪴", "书包": "🎒",
}

# 新旧程度映射
CONDITION_MAP = {
    1: "全新", 2: "几乎全新", 3: "轻微痕迹", 4: "明显痕迹", 5: "成色一般",
    6: "成色一般", 7: "七成新", 8: "八成新", 9: "九成新", 10: "全新未拆",
}


def parse_products_from_sql(sql_path):
    """从 SQL dump 解析商品数据"""
    with open(sql_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 匹配 INSERT INTO `products` VALUES (...)
    pattern = r"INSERT INTO `products` VALUES\s*(.*?);"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        print("ERROR: 未找到 products INSERT 语句")
        return []

    values_str = match.group(1)
    # 按括号分组解析每条记录
    products = []
    # 匹配每条 (id, seller_id, category_id, title, description, price, original_price, condition, images, ...)
    record_pattern = r"\((\d+),(\d+),(\d+),'((?:[^'\\]|\\.)*)','((?:[^'\\]|\\.)*)',([\d.]+),([\d.]+),(\d+),(NULL|'(?:[^'\\]|\\.)*'),(\d+),(\d+),(\d+),'([^']*)','[^']*'(?:,'[^']*')?(?:,(NULL|'(?:[^'\\]|\\.)*'))?\)"
    
    for m in re.finditer(record_pattern, values_str):
        product = {
            "id": int(m.group(1)),
            "seller_id": int(m.group(2)),
            "category_id": int(m.group(3)),
            "title": m.group(4).replace("\\n", "").replace("\\'", "'").strip(),
            "description": m.group(5).replace("\\n", "").replace("\\'", "'").strip(),
            "price": float(m.group(6)),
            "original_price": float(m.group(7)),
            "condition": int(m.group(8)),
            "images_raw": m.group(9),
            "status": int(m.group(10)),
            "view_count": int(m.group(11)),
            "fav_count": int(m.group(12)),
            "location": m.group(13),
        }
        # 跳过已有图片的商品
        has_image = product["images_raw"] != "NULL" and product["images_raw"].strip() != "''"
        product["has_image"] = has_image
        products.append(product)

    return products


def get_emoji_for_product(title, category_id):
    """根据标题关键词和分类获取最合适的 emoji"""
    for keyword, emoji in KEYWORD_EMOJI.items():
        if keyword.lower() in title.lower():
            return emoji
    # 回退到分类默认
    config = CATEGORY_CONFIG.get(category_id, CATEGORY_CONFIG[18])
    return config["emoji"]


def get_font(size, bold=False):
    """获取中文字体"""
    font_paths = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Medium.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def get_emoji_font(size):
    """获取 emoji 字体"""
    emoji_paths = [
        "/System/Library/Fonts/Apple Color Emoji.ttc",
        "/System/Library/Fonts/Segoe UI Emoji.ttf",
    ]
    for path in emoji_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return None


def create_gradient(size, color1, color2, angle=135):
    """创建对角渐变背景"""
    width, height = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)

    # 计算渐变方向
    rad = math.radians(angle)
    dx = math.cos(rad)
    dy = math.sin(rad)

    for y in range(height):
        for x in range(width):
            # 计算渐变位置 (0~1)
            t = (x * dx + y * dy) / (width * abs(dx) + height * abs(dy))
            t = max(0, min(1, t))
            r = int(color1[0] + (color2[0] - color1[0]) * t)
            g = int(color1[1] + (color2[1] - color1[1]) * t)
            b = int(color1[2] + (color2[2] - color1[2]) * t)
            draw.point((x, y), fill=(r, g, b))

    return img


def create_gradient_fast(size, color1, color2, angle=135):
    """快速创建渐变 - 生成小尺寸渐变后放大"""
    w, h = size
    # 生成小尺寸渐变 (1/4)，然后放大
    sw, sh = max(1, w // 4), max(1, h // 4)
    small = Image.new("RGB", (sw, sh))
    sp = small.load()

    rad = math.radians(angle)
    dx = math.cos(rad)
    dy = math.sin(rad)
    denom = sw * abs(dx) + sh * abs(dy)
    if denom == 0:
        denom = 1

    for y in range(sh):
        for x in range(sw):
            t = (x * dx + y * dy) / denom
            t = max(0.0, min(1.0, t))
            r = int(color1[0] + (color2[0] - color1[0]) * t)
            g = int(color1[1] + (color2[1] - color1[1]) * t)
            b = int(color1[2] + (color2[2] - color1[2]) * t)
            sp[x, y] = (r, g, b)

    return small.resize(size, Image.BILINEAR)


def draw_rounded_rect(draw, xy, radius, fill):
    """绘制圆角矩形"""
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def wrap_text(text, font, max_width, draw):
    """文字自动换行"""
    lines = []
    current = ""
    for char in text:
        test = current + char
        bbox = draw.textbbox((0, 0), test, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = char
    if current:
        lines.append(current)
    return lines


def generate_product_image(product, output_path):
    """为单个商品生成占位图"""
    cat_id = product["category_id"]
    config = CATEGORY_CONFIG.get(cat_id, CATEGORY_CONFIG[18])

    # 创建渐变背景
    img = create_gradient_fast(
        (IMG_SIZE, IMG_SIZE),
        tuple(config["gradient"][0]),
        tuple(config["gradient"][1]),
        angle=135,
    )
    draw = ImageDraw.Draw(img, "RGBA")

    # ── 顶部：分类标签 ──
    cat_font = get_font(22)
    cat_text = config["name"]
    cat_bbox = draw.textbbox((0, 0), cat_text, font=cat_font)
    cat_w = cat_bbox[2] - cat_bbox[0]
    cat_padding = 20
    badge_x1 = IMG_SIZE // 2 - (cat_w + cat_padding * 2) // 2
    badge_y1 = 30
    badge_x2 = badge_x1 + cat_w + cat_padding * 2
    badge_y2 = badge_y1 + 44

    # 半透明白色圆角背景
    draw_rounded_rect(draw, (badge_x1, badge_y1, badge_x2, badge_y2), 22, (255, 255, 255, 80))
    draw.text(
        (IMG_SIZE // 2 - cat_w // 2, badge_y1 + 8),
        cat_text,
        fill=(255, 255, 255, 230),
        font=cat_font,
    )

    # ── 中间：大号 emoji 或文字图标 ──
    emoji_str = get_emoji_for_product(product["title"], cat_id)
    emoji_font = get_emoji_font(140)
    text_font = get_font(120, bold=True)

    if emoji_font:
        # 尝试用 emoji 字体渲染
        try:
            ebbox = draw.textbbox((0, 0), emoji_str, font=emoji_font)
            ew = ebbox[2] - ebbox[0]
            eh = ebbox[3] - ebbox[1]
            draw.text(
                ((IMG_SIZE - ew) // 2 - ebbox[0], 160 - ebbox[1]),
                emoji_str,
                fill=(255, 255, 255, 255),
                font=emoji_font,
            )
        except Exception:
            # 回退到文字
            label = config["label"]
            lbbox = draw.textbbox((0, 0), label, font=text_font)
            lw = lbbox[2] - lbbox[0]
            lh = lbbox[3] - lbbox[1]
            draw.text(
                ((IMG_SIZE - lw) // 2, 180),
                label,
                fill=(255, 255, 255, 200),
                font=text_font,
            )
    else:
        label = config["label"]
        lbbox = draw.textbbox((0, 0), label, font=text_font)
        lw = lbbox[2] - lbbox[0]
        draw.text(
            ((IMG_SIZE - lw) // 2, 180),
            label,
            fill=(255, 255, 255, 200),
            font=text_font,
        )

    # ── 底部区域：半透明白色底板 ──
    bottom_y = 370
    draw.rounded_rectangle(
        (20, bottom_y, IMG_SIZE - 20, IMG_SIZE - 20),
        radius=20,
        fill=(255, 255, 255, 240),
    )

    # 商品名称
    title_font = get_font(30, bold=True)
    title_lines = wrap_text(product["title"], title_font, IMG_SIZE - 80, draw)
    ty = bottom_y + 24
    for line in title_lines[:3]:
        draw.text((40, ty), line, fill=(45, 42, 38), font=title_font)
        ty += 40

    # 成色标签
    cond_text = CONDITION_MAP.get(product["condition"], "二手")
    cond_font = get_font(20)
    cond_bbox = draw.textbbox((0, 0), cond_text, font=cond_font)
    cw = cond_bbox[2] - cond_bbox[0]
    cond_y = ty + 6
    draw.rounded_rectangle(
        (40, cond_y, 40 + cw + 24, cond_y + 32),
        radius=16,
        fill=config["gradient"][0] + (60,),
    )
    draw.text((52, cond_y + 5), cond_text, fill=(255, 255, 255, 230), font=cond_font)

    # 价格
    price_font = get_font(42, bold=True)
    price_str = f"¥{product['price']:.0f}" if product["price"] == int(product["price"]) else f"¥{product['price']:.2f}"
    if product["price"] == 0:
        price_str = "免费"
    price_bbox = draw.textbbox((0, 0), price_str, font=price_font)
    pw = price_bbox[2] - price_bbox[0]
    draw.text(
        (IMG_SIZE - 40 - pw, IMG_SIZE - 70),
        price_str,
        fill=tuple(config["gradient"][1]),
        font=price_font,
    )

    # 原价划线
    if product["original_price"] > product["price"] and product["price"] > 0:
        orig_font = get_font(20)
        orig_str = f"¥{product['original_price']:.0f}"
        obbox = draw.textbbox((0, 0), orig_str, font=orig_font)
        ow = obbox[2] - obbox[0]
        ox = IMG_SIZE - 40 - pw - ow - 12
        oy = IMG_SIZE - 58
        draw.text((ox, oy), orig_str, fill=(160, 160, 160), font=orig_font)
        # 划线
        draw.line((ox, oy + 14, ox + ow, oy + 14), fill=(160, 160, 160), width=2)

    # ── 底部水印 ──
    watermark_font = get_font(16)
    wm_text = "校园助手 · 阳光集市"
    wm_bbox = draw.textbbox((0, 0), wm_text, font=watermark_font)
    ww = wm_bbox[2] - wm_bbox[0]
    # 画在底部白色区域最下方
    draw.text(
        (IMG_SIZE // 2 - ww // 2, IMG_SIZE - 42),
        wm_text,
        fill=(180, 180, 180),
        font=watermark_font,
    )

    img.save(output_path, "PNG", optimize=True)


def main():
    print("📋 解析 SQL 数据...")
    products = parse_products_from_sql(SQL_FILE)
    print(f"   找到 {len(products)} 个商品")

    # 筛选需要生成图片的商品（没有图片 + 状态为售卖中）
    need_images = [p for p in products if not p["has_image"] and p["status"] == 1]
    print(f"   需要生成图片: {need_images.__len__()} 个（无图且在售）")

    # 也包含已有图片的，全部重新生成
    all_products = [p for p in products if p["status"] == 1]
    print(f"   在售商品总数: {len(all_products)} 个")

    os.makedirs(UPLOADS_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(SQL_OUTPUT), exist_ok=True)

    sql_lines = ["-- 商品图片批量更新 SQL", "-- 自动生成，执行即可", ""]
    generated = 0
    skipped = 0

    for product in all_products:
        pid = product["id"]
        # 生成文件名
        filename = f"gen_prod_{pid}.png"
        filepath = os.path.join(UPLOADS_DIR, filename)
        image_url = f"/uploads/{filename}"

        try:
            generate_product_image(product, filepath)
            # 生成 SQL
            images_json = json.dumps([image_url], ensure_ascii=False)
            sql_lines.append(
                f"UPDATE `products` SET `images` = '{images_json}' WHERE `id` = {pid};"
            )
            generated += 1
            if generated % 20 == 0:
                print(f"   已生成 {generated}/{len(all_products)}...")
        except Exception as e:
            print(f"   ❌ 商品 {pid} 生成失败: {e}")
            skipped += 1

    # 写入 SQL 文件
    with open(SQL_OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(sql_lines))

    print(f"\n✅ 完成！")
    print(f"   生成图片: {generated} 张")
    print(f"   失败: {skipped} 个")
    print(f"   图片目录: {UPLOADS_DIR}")
    print(f"   SQL 文件: {SQL_OUTPUT}")


if __name__ == "__main__":
    main()
