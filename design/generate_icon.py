"""
Genera l'icona dell'app (cornetta telefonica + simbolo di divieto) e la
esporta in tutte le dimensioni richieste da iOS e Android.

Uso: .venv/bin/python generate_icon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND_COLOR = (30, 41, 82, 255)  # blu/indaco scuro
GLYPH_COLOR = (255, 255, 255, 255)  # bianco
PROHIBIT_COLOR = (229, 57, 53, 255)  # rosso

MASTER_SIZE = 1024

ROOT = Path(__file__).parent
IOS_APPICON_DIR = ROOT.parent / "ios" / "NoSpam" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_RES_DIR = ROOT.parent / "android" / "app" / "src" / "main" / "res"


def draw_handset(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Cornetta telefonica vista di profilo: una curva a S spessa tra padiglione
    auricolare (in alto) e microfono (in basso), come nella classica icona
    "telefono" (es. app Telefono di iOS)."""
    center = size / 2

    # Bezier quadratica: P0 = microfono (basso sinistra), P2 = auricolare
    # (alto destra), P1 = punto di controllo che crea la curvatura a "C".
    p0 = (center - 0.20 * size, center + 0.24 * size)
    p2 = (center + 0.20 * size, center - 0.24 * size)
    p1 = (center - 0.16 * size, center - 0.16 * size)

    # Disegniamo la curva come tanti cerchi pieni sovrapposti (invece di una
    # linea con "width"): ImageDraw.line con tratti larghi su molti segmenti
    # brevi lascia giunture visibili e seghettate lungo i bordi.
    stroke_width = size * 0.085
    cap_r = stroke_width / 2
    steps = 240
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t**2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t**2 * p2[1]
        draw.ellipse([x - cap_r, y - cap_r, x + cap_r, y + cap_r], fill=GLYPH_COLOR)

    # Padiglioni auricolare e microfono, piu' grandi alle due estremita'.
    end_r = size * 0.135
    for x, y in (p0, p2):
        draw.ellipse([x - end_r, y - end_r, x + end_r, y + end_r], fill=GLYPH_COLOR)


def draw_prohibition_sign(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Cerchio rosso con barra diagonale, sovrapposto alla cornetta."""
    center = size / 2
    radius = size * 0.42
    ring_width = size * 0.075

    bbox = [center - radius, center - radius, center + radius, center + radius]
    draw.ellipse(bbox, outline=PROHIBIT_COLOR, width=int(ring_width))

    angle = math.radians(45)
    bar_len = radius - ring_width / 2
    x1 = center - bar_len * math.cos(angle)
    y1 = center - bar_len * math.sin(angle)
    x2 = center + bar_len * math.cos(angle)
    y2 = center + bar_len * math.sin(angle)
    draw.line([x1, y1, x2, y2], fill=PROHIBIT_COLOR, width=int(ring_width))


def render_glyph(size: int, transparent_background: bool) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0) if transparent_background else BACKGROUND_COLOR)
    draw = ImageDraw.Draw(image)
    draw_handset(draw, size)
    draw_prohibition_sign(draw, size)
    return image


def export_ios() -> None:
    IOS_APPICON_DIR.mkdir(parents=True, exist_ok=True)
    master = render_glyph(MASTER_SIZE, transparent_background=False).convert("RGB")

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
    # Adaptive icon: sfondo colore piatto + foreground trasparente, minSdk 29
    # non richiede fallback legacy (mipmap quadrati/round pre-Android 8).
    densities = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }

    # Il glifo deve stare nella "safe zone" centrale (66dp su 108dp) per non
    # essere tagliato dalla maschera adattiva del sistema.
    safe_zone_ratio = 0.60

    for folder, canvas_size in densities.items():
        target_dir = ANDROID_RES_DIR / folder
        target_dir.mkdir(parents=True, exist_ok=True)

        glyph_size = int(canvas_size * safe_zone_ratio)
        glyph = render_glyph(glyph_size, transparent_background=True)

        canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        offset = (canvas_size - glyph_size) // 2
        canvas.paste(glyph, (offset, offset), glyph)
        canvas.save(target_dir / "ic_launcher_foreground.png")

    values_dir = ANDROID_RES_DIR / "values"
    values_dir.mkdir(parents=True, exist_ok=True)
    color_hex = "#{:02X}{:02X}{:02X}".format(*BACKGROUND_COLOR[:3])
    colors_path = values_dir / "ic_launcher_background_color.xml"
    colors_path.write_text(
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
    render_glyph(512, transparent_background=False).convert("RGB").save(preview_path)
    print(f"Anteprima: {preview_path}")

    export_ios()
    export_android()


if __name__ == "__main__":
    main()
