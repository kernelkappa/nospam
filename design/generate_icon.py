"""
Genera l'icona dell'app a partire dal glifo Material Symbols
"phone_disabled" (Google, licenza Apache 2.0 - vedi assets/LICENSE) e la
esporta in tutte le dimensioni richieste da iOS e Android.

Uso: .venv/bin/python generate_icon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw
from reportlab.graphics import renderPM
from svglib.svglib import svg2rlg

BACKGROUND_COLOR = (30, 41, 82, 255)  # blu/indaco scuro
GLYPH_COLOR = "#FFFFFF"
PROHIBIT_COLOR = (229, 57, 53, 255)  # rosso

MASTER_SIZE = 1024
BADGE_SCALE = 0.66  # frazione della tela occupata dal cerchio di divieto

ROOT = Path(__file__).parent
SOURCE_SVG = ROOT / "assets" / "phone_disabled.svg"
IOS_APPICON_DIR = ROOT.parent / "ios" / "NoSpam" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_RES_DIR = ROOT.parent / "android" / "app" / "src" / "main" / "res"


def render_glyph(size: int) -> Image.Image:
    svg_text = SOURCE_SVG.read_text(encoding="utf-8").replace("<path ", f'<path fill="{GLYPH_COLOR}" ', 1)
    tmp_svg = ROOT / "_tmp_glyph.svg"
    tmp_svg.write_text(svg_text, encoding="utf-8")
    try:
        drawing = svg2rlg(str(tmp_svg))
        scale = size / max(drawing.width, drawing.height)
        drawing.width *= scale
        drawing.height *= scale
        drawing.scale(scale, scale)
        png_path = ROOT / "_tmp_glyph.png"
        renderPM.drawToFile(drawing, str(png_path), fmt="PNG", bg=0x000000)
        rendered = Image.open(png_path).convert("RGB")

        # Il glifo e' bianco su sfondo nero: usiamo la luminanza come canale
        # alpha (bianco -> opaco, nero -> trasparente) invece di affidarci al
        # color-keying di renderPM, che con questo backend non funziona.
        luminance = rendered.convert("L")
        glyph = Image.new("RGBA", rendered.size, (255, 255, 255, 0))
        glyph.putalpha(luminance)
    finally:
        tmp_svg.unlink(missing_ok=True)
        (ROOT / "_tmp_glyph.png").unlink(missing_ok=True)
    return glyph


def draw_prohibition_sign(draw: ImageDraw.ImageDraw, canvas_size: int, badge_scale: float) -> None:
    center = canvas_size / 2
    radius = canvas_size * badge_scale / 2
    ring_width = radius * 0.19

    bbox = [center - radius, center - radius, center + radius, center + radius]
    draw.ellipse(bbox, outline=PROHIBIT_COLOR, width=int(ring_width))

    angle = math.radians(45)
    bar_len = radius - ring_width / 2
    x1 = center - bar_len * math.cos(angle)
    y1 = center - bar_len * math.sin(angle)
    x2 = center + bar_len * math.cos(angle)
    y2 = center + bar_len * math.sin(angle)
    draw.line([x1, y1, x2, y2], fill=PROHIBIT_COLOR, width=int(ring_width))


def compose(canvas_size: int, transparent_background: bool, badge_scale: float = BADGE_SCALE) -> Image.Image:
    background = (0, 0, 0, 0) if transparent_background else BACKGROUND_COLOR
    canvas = Image.new("RGBA", (canvas_size, canvas_size), background)

    # Il glifo occupa la parte interna del cerchio (come nei segnali di
    # divieto stradali: l'icona al centro e' piu' piccola dell'anello).
    glyph_size = int(canvas_size * badge_scale * 0.66)
    glyph = render_glyph(glyph_size)
    # La renderPM esporta un canvas rettangolare con margini: ritagliamo al
    # contenuto non trasparente per poterlo centrare correttamente.
    bbox = glyph.getbbox()
    if bbox:
        glyph = glyph.crop(bbox)
    glyph.thumbnail((glyph_size, glyph_size), Image.LANCZOS)

    offset = ((canvas_size - glyph.width) // 2, (canvas_size - glyph.height) // 2)
    canvas.paste(glyph, offset, glyph)

    draw = ImageDraw.Draw(canvas)
    draw_prohibition_sign(draw, canvas_size, badge_scale)
    return canvas


def export_ios() -> None:
    IOS_APPICON_DIR.mkdir(parents=True, exist_ok=True)
    master = compose(MASTER_SIZE, transparent_background=False).convert("RGB")

    sizes = {
        "icon-20@2x.png": 40,
        "icon-20@3x.png": 60,
        "icon-29@2x.png": 58,
        "icon-29@3x.png": 87,
        "icon-40@2x.png": 80,
        "icon-40@3x.png": 120,
        "icon-60@2x.png": 120,
        "icon-60@3x.png": 180,
        "icon-1024.png": 1024,
    }
    for filename, px in sizes.items():
        master.resize((px, px), Image.LANCZOS).save(IOS_APPICON_DIR / filename)

    contents = {
        "images": [
            {"filename": "icon-20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
            {"filename": "icon-20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
            {"filename": "icon-29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
            {"filename": "icon-29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
            {"filename": "icon-40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
            {"filename": "icon-40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
            {"filename": "icon-60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
            {"filename": "icon-60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
            {"filename": "icon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    import json

    (IOS_APPICON_DIR / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
    print(f"iOS: scritte {len(sizes)} immagini + Contents.json in {IOS_APPICON_DIR}")


def export_android() -> None:
    densities = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    # Il badge (cerchio + glifo) deve stare nella "safe zone" (66dp su
    # 108dp) per non essere tagliato dalla maschera adattiva del sistema.
    safe_zone_scale = 0.58

    for folder, canvas_size in densities.items():
        target_dir = ANDROID_RES_DIR / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        image = compose(canvas_size, transparent_background=True, badge_scale=safe_zone_scale)
        image.save(target_dir / "ic_launcher_foreground.png")

    values_dir = ANDROID_RES_DIR / "values"
    values_dir.mkdir(parents=True, exist_ok=True)
    color_hex = "#{:02X}{:02X}{:02X}".format(*BACKGROUND_COLOR[:3])
    (values_dir / "ic_launcher_background_color.xml").write_text(
        f'<?xml version="1.0" encoding="utf-8"?>\n'
        f"<resources>\n"
        f'    <color name="ic_launcher_background">{color_hex}</color>\n'
        f"</resources>\n",
        encoding="utf-8",
    )

    anydpi_dir = ANDROID_RES_DIR / "mipmap-anydpi-v26"
    anydpi_dir.mkdir(parents=True, exist_ok=True)
    adaptive_icon_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (anydpi_dir / "ic_launcher.xml").write_text(adaptive_icon_xml, encoding="utf-8")
    (anydpi_dir / "ic_launcher_round.xml").write_text(adaptive_icon_xml, encoding="utf-8")

    print(f"Android: scritti foreground per {len(densities)} densita' + adaptive-icon XML")


def main() -> None:
    preview_path = ROOT / "icon_preview.png"
    compose(512, transparent_background=False).convert("RGB").save(preview_path)
    print(f"Anteprima: {preview_path}")

    export_ios()
    export_android()


if __name__ == "__main__":
    main()
