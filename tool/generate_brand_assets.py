#!/usr/bin/env python3
"""
Anchor Brand Asset Generator
============================
Deterministic, Pillow-only script that creates all brand assets from source masters.

BRAND RULES:
1. The glyph is NEVER stretched, rotated, outlined, or given shadows/drop-effects.
2. Glyph colors:
   - Light surfaces: Black (#111111 equivalent: pure source pixels).
   - Dark surfaces: Pure white (#FFFFFF: tint source RGB to 255 while preserving alpha).
3. Minimum clear space around the glyph: 25% of its width.
4. Tile backgrounds:
   - Light tile: Pure White #FFFFFF.
   - Dark tile: Near-black #0E0E10 (matches AppPalette dark background).
5. Never use accent colors on the logo mark; the Anchor logo is strictly monochrome by design.
"""

import os
import shutil
import struct
import numpy as np
from PIL import Image, ImageDraw, ImageFont

# Path definitions
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(ROOT_DIR, "assets", "branding")
SOURCE_DIR = os.path.join(ASSETS_DIR, "source")
ANDROID_OUT = os.path.join(ASSETS_DIR, "android")
WINDOWS_OUT = os.path.join(ASSETS_DIR, "windows")
WEB_OUT = os.path.join(ASSETS_DIR, "web")
INAPP_OUT = os.path.join(ASSETS_DIR, "inapp")
SITE_OUT = os.path.join(ROOT_DIR, "site")
WEB_DIR = os.path.join(ROOT_DIR, "web")
ANDROID_RES = os.path.join(ROOT_DIR, "android", "app", "src", "main", "res")
WINDOWS_RES = os.path.join(ROOT_DIR, "windows", "runner", "resources")
FONTS_DIR = os.path.join(ROOT_DIR, "assets", "fonts")

FONT_SEMIBOLD = os.path.join(FONTS_DIR, "Inter-SemiBold.ttf")
FONT_REGULAR = os.path.join(FONTS_DIR, "Inter-Regular.ttf")
FONT_MEDIUM = os.path.join(FONTS_DIR, "Inter-Medium.ttf")

# Color Constants
COLOR_LIGHT_BG = (255, 255, 255)
COLOR_DARK_BG = (14, 14, 16)      # #0E0E10
COLOR_GLYPH_BLACK = (17, 17, 17)  # #111111
COLOR_GLYPH_WHITE = (255, 255, 255)


def ensure_dirs():
    for d in [
        ASSETS_DIR, SOURCE_DIR, ANDROID_OUT, WINDOWS_OUT, WEB_OUT,
        INAPP_OUT, SITE_OUT, WEB_DIR, ANDROID_RES, WINDOWS_RES
    ]:
        os.makedirs(d, exist_ok=True)


def clean_source_masters():
    """Validates source files, trims glyph to exact bounding box, centers in 1024x1024."""
    trans_path = os.path.join(SOURCE_DIR, "anchor_symbol_transparent_1024.png")
    mono_path = os.path.join(SOURCE_DIR, "anchor_android_monochrome_1024.png")
    white_path = os.path.join(SOURCE_DIR, "anchor_selected_black_on_white_1024.png")

    assert os.path.exists(trans_path), f"Missing {trans_path}"
    assert os.path.exists(mono_path), f"Missing {mono_path}"
    assert os.path.exists(white_path), f"Missing {white_path}"

    im_trans = Image.open(trans_path).convert("RGBA")
    bbox = im_trans.getbbox()
    assert bbox is not None, "Glyph is empty"

    # Crop to glyph
    glyph_crop = im_trans.crop(bbox)
    gw, gh = glyph_crop.size

    # Create 1024x1024 canvas and center the cropped glyph exactly
    canvas_black = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    paste_x = (1024 - gw) // 2
    paste_y = (1024 - gh) // 2
    canvas_black.paste(glyph_crop, (paste_x, paste_y), mask=glyph_crop.split()[3])

    # Save cleaned transparent black master
    clean_trans = os.path.join(SOURCE_DIR, "anchor_symbol_transparent_1024_clean.png")
    canvas_black.save(clean_trans, "PNG")

    # Create clean white glyph (preserve alpha, set RGB to 255)
    r, g, b, a = canvas_black.split()
    white_rgb = Image.new("RGB", (1024, 1024), (255, 255, 255))
    canvas_white = Image.merge("RGBA", (*white_rgb.split(), a))
    clean_white = os.path.join(SOURCE_DIR, "anchor_symbol_white_1024_clean.png")
    canvas_white.save(clean_white, "PNG")

    # Clean monochrome master (pure black with exact alpha)
    black_rgb = Image.new("RGB", (1024, 1024), (0, 0, 0))
    canvas_mono = Image.merge("RGBA", (*black_rgb.split(), a))
    clean_mono = os.path.join(SOURCE_DIR, "anchor_android_monochrome_1024_clean.png")
    canvas_mono.save(clean_mono, "PNG")

    # Clean black on white tile
    tile_light = Image.new("RGB", (1024, 1024), COLOR_LIGHT_BG)
    tile_light.paste(canvas_black, (0, 0), mask=a)
    clean_bow = os.path.join(SOURCE_DIR, "anchor_selected_black_on_white_1024_clean.png")
    tile_light.save(clean_bow, "PNG")

    return canvas_black, canvas_white, canvas_mono, tile_light


def generate_core_assets(master_black, master_white):
    """Generates the 4 main assets declared in pubspec.yaml."""
    # 1. glyph_black.png (transparent, black, 1024)
    master_black.save(os.path.join(ASSETS_DIR, "glyph_black.png"), "PNG")

    # 2. glyph_white.png (transparent, white, 1024)
    master_white.save(os.path.join(ASSETS_DIR, "glyph_white.png"), "PNG")

    # 3. tile_light_1024.png (glyph on white, square, full-bleed)
    tile_light = Image.new("RGB", (1024, 1024), COLOR_LIGHT_BG)
    tile_light.paste(master_black, (0, 0), mask=master_black.split()[3])
    tile_light.save(os.path.join(ASSETS_DIR, "tile_light_1024.png"), "PNG")

    # 4. tile_dark_1024.png (white glyph on #0E0E10, square)
    tile_dark = Image.new("RGB", (1024, 1024), COLOR_DARK_BG)
    tile_dark.paste(master_white, (0, 0), mask=master_white.split()[3])
    tile_dark.save(os.path.join(ASSETS_DIR, "tile_dark_1024.png"), "PNG")

    # In-app splash
    master_black.save(os.path.join(INAPP_OUT, "splash_light.png"), "PNG")
    master_white.save(os.path.join(INAPP_OUT, "splash_dark.png"), "PNG")


def generate_rounded_tile(glyph_black, size, radius_ratio=0.22, glyph_ratio=0.56):
    """Generates a rounded tile with the glyph at the center."""
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    radius = int(size * radius_ratio)
    draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=COLOR_LIGHT_BG)

    # Scale glyph
    gw, gh = glyph_black.size
    bbox = glyph_black.getbbox()
    glyph_crop = glyph_black.crop(bbox)
    target_h = int(size * glyph_ratio)
    target_w = int(glyph_crop.width * (target_h / glyph_crop.height))
    scaled_glyph = glyph_crop.resize((target_w, target_h), Image.Resampling.LANCZOS)

    gx = (size - target_w) // 2
    gy = (size - target_h) // 2
    tile.paste(scaled_glyph, (gx, gy), mask=scaled_glyph.split()[3])
    return tile


def generate_android_assets(master_black, master_white):
    """Generates Android adaptive icons, legacy icons, notification small icons, and store graphics."""
    bbox = master_black.getbbox()
    glyph_crop_black = master_black.crop(bbox)
    glyph_crop_white = master_white.crop(bbox)

    # 1. Adaptive Icon Foreground: 432x432 (108dp @4x), safe zone 66% (diameter 285px)
    # Glyph height 260px has max radius ~129px <= 142.5px safe circle
    fg_size = 432
    target_h = 260
    target_w = int(glyph_crop_black.width * (target_h / glyph_crop_black.height))

    scaled_black_fg = glyph_crop_black.resize((target_w, target_h), Image.Resampling.LANCZOS)
    fg_img = Image.new("RGBA", (fg_size, fg_size), (0, 0, 0, 0))
    paste_x = (fg_size - target_w) // 2
    paste_y = (fg_size - target_h) // 2
    fg_img.paste(scaled_black_fg, (paste_x, paste_y), mask=scaled_black_fg.split()[3])
    fg_img.save(os.path.join(ANDROID_OUT, "ic_launcher_foreground.png"), "PNG")

    # 2. Adaptive Icon Background: 432x432 solid white
    bg_img = Image.new("RGB", (fg_size, fg_size), COLOR_LIGHT_BG)
    bg_img.save(os.path.join(ANDROID_OUT, "ic_launcher_background.png"), "PNG")

    # 3. Adaptive Icon Monochrome: 432x432 transparent for Android 13 themed icons
    mono_img = fg_img.copy()
    mono_img.save(os.path.join(ANDROID_OUT, "ic_launcher_monochrome.png"), "PNG")

    # Generate adaptive foreground & monochrome at all Android densities
    fg_densities = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    for dens, size in fg_densities.items():
        res_dir = os.path.join(ANDROID_RES, f"drawable-{dens}")
        os.makedirs(res_dir, exist_ok=True)
        d_gh = int(size * (260 / 432))
        d_gw = int(glyph_crop_black.width * (d_gh / glyph_crop_black.height))
        sc_fg = glyph_crop_black.resize((d_gw, d_gh), Image.Resampling.LANCZOS)
        d_fg_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d_fg_img.paste(sc_fg, ((size - d_gw) // 2, (size - d_gh) // 2), mask=sc_fg.split()[3])
        d_fg_img.save(os.path.join(res_dir, "ic_launcher_foreground.png"), "PNG")
        d_fg_img.save(os.path.join(res_dir, "ic_launcher_monochrome.png"), "PNG")

    os.makedirs(os.path.join(ANDROID_RES, "drawable"), exist_ok=True)
    shutil.copy2(
        os.path.join(ANDROID_RES, "drawable-xxxhdpi", "ic_launcher_foreground.png"),
        os.path.join(ANDROID_RES, "drawable", "ic_launcher_foreground.png")
    )
    shutil.copy2(
        os.path.join(ANDROID_RES, "drawable-xxxhdpi", "ic_launcher_monochrome.png"),
        os.path.join(ANDROID_RES, "drawable", "ic_launcher_monochrome.png")
    )

    # Adaptive icon XMLs: mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml
    v26_dir = os.path.join(ANDROID_RES, "mipmap-anydpi-v26")
    os.makedirs(v26_dir, exist_ok=True)
    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
'''
    with open(os.path.join(v26_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    with open(os.path.join(v26_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    # Background color resource
    values_dir = os.path.join(ANDROID_RES, "values")
    os.makedirs(values_dir, exist_ok=True)
    bg_xml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
'''
    with open(os.path.join(values_dir, "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
        f.write(bg_xml)

    # 4. Notification Small Icons: white glyph on transparent, 24dp
    notif_densities = {
        "mdpi": (24, 20),
        "hdpi": (36, 30),
        "xhdpi": (48, 40),
        "xxhdpi": (72, 60),
        "xxxhdpi": (96, 80),
    }

    for dens, (canvas_s, glyph_s) in notif_densities.items():
        gw = int(glyph_crop_white.width * (glyph_s / glyph_crop_white.height))
        sc_white = glyph_crop_white.resize((gw, glyph_s), Image.Resampling.LANCZOS)
        # Force RGB to pure 255 so anti-aliasing only affects alpha channel (no gray fringing)
        w_rgb = Image.new("RGB", sc_white.size, (255, 255, 255))
        sc_white = Image.merge("RGBA", (*w_rgb.split(), sc_white.split()[3]))

        notif_img = Image.new("RGBA", (canvas_s, canvas_s), (0, 0, 0, 0))
        nx = (canvas_s - gw) // 2
        ny = (canvas_s - glyph_s) // 2
        notif_img.paste(sc_white, (nx, ny), mask=sc_white.split()[3])
        # Ensure all pixels in notification icon have RGB = (255, 255, 255)
        r, g, b, a = notif_img.split()
        full_white = Image.new("RGB", notif_img.size, (255, 255, 255))
        notif_img = Image.merge("RGBA", (*full_white.split(), a))

        # Save to assets/branding/android/
        notif_img.save(os.path.join(ANDROID_OUT, f"ic_stat_anchor_{dens}.png"), "PNG")

        # Copy to android/app/src/main/res/drawable-<dens>/ic_stat_anchor.png
        res_dir = os.path.join(ANDROID_RES, f"drawable-{dens}")
        os.makedirs(res_dir, exist_ok=True)
        notif_img.save(os.path.join(res_dir, "ic_stat_anchor.png"), "PNG")

    # Copy also to unadorned drawable/ for fallback
    os.makedirs(os.path.join(ANDROID_RES, "drawable"), exist_ok=True)
    shutil.copy2(
        os.path.join(ANDROID_OUT, "ic_stat_anchor_hdpi.png"),
        os.path.join(ANDROID_RES, "drawable", "ic_stat_anchor.png")
    )

    # 5. Play Store Icon: 512x512 full bleed white square, glyph at 62% of width
    play_size = 512
    play_gh = int(play_size * 0.62)
    play_gw = int(glyph_crop_black.width * (play_gh / glyph_crop_black.height))
    scaled_play = glyph_crop_black.resize((play_gw, play_gh), Image.Resampling.LANCZOS)
    play_img = Image.new("RGB", (play_size, play_size), COLOR_LIGHT_BG)
    px = (play_size - play_gw) // 2
    py = (play_size - play_gh) // 2
    play_img.paste(scaled_play, (px, py), mask=scaled_play.split()[3])
    play_img.save(os.path.join(ANDROID_OUT, "playstore_512.png"), "PNG")

    # 6. Feature Graphic: 1024x500 white background, centered glyph + wordmark "anchor"
    feat_img = Image.new("RGB", (1024, 500), COLOR_LIGHT_BG)
    draw_feat = ImageDraw.Draw(feat_img)
    font_feat = ImageFont.truetype(FONT_SEMIBOLD, 96)

    # Lockup: [Glyph (140h)] [24px gap] [Text "anchor"]
    feat_gh = 140
    feat_gw = int(glyph_crop_black.width * (feat_gh / glyph_crop_black.height))
    scaled_feat_glyph = glyph_crop_black.resize((feat_gw, feat_gh), Image.Resampling.LANCZOS)

    text_str = "anchor"
    text_bbox = draw_feat.textbbox((0, 0), text_str, font=font_feat)
    text_w = text_bbox[2] - text_bbox[0]
    text_h = text_bbox[3] - text_bbox[1]

    gap = 24
    total_w = feat_gw + gap + text_w
    start_x = (1024 - total_w) // 2
    glyph_y = (500 - feat_gh) // 2
    text_y = (500 - text_h) // 2 - text_bbox[1]

    feat_img.paste(scaled_feat_glyph, (start_x, glyph_y), mask=scaled_feat_glyph.split()[3])
    draw_feat.text((start_x + feat_gw + gap, text_y), text_str, font=font_feat, fill=COLOR_GLYPH_BLACK)
    feat_img.save(os.path.join(ANDROID_OUT, "feature_graphic_1024x500.png"), "PNG")

    # 7. Legacy Launcher Icons (mipmap-mdpi..xxxhdpi)
    legacy_densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }

    for dens, size in legacy_densities.items():
        # Square legacy icon (glyph on white)
        sq_img = Image.new("RGB", (size, size), COLOR_LIGHT_BG)
        leg_gh = int(size * 0.62)
        leg_gw = int(glyph_crop_black.width * (leg_gh / glyph_crop_black.height))
        sc_leg = glyph_crop_black.resize((leg_gw, leg_gh), Image.Resampling.LANCZOS)
        lx = (size - leg_gw) // 2
        ly = (size - leg_gh) // 2
        sq_img.paste(sc_leg, (lx, ly), mask=sc_leg.split()[3])

        # Round legacy icon (circle mask)
        round_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw_r = ImageDraw.Draw(round_img)
        draw_r.ellipse([(0, 0), (size - 1, size - 1)], fill=COLOR_LIGHT_BG)
        round_img.paste(sc_leg, (lx, ly), mask=sc_leg.split()[3])

        # Write to res/mipmap-<dens>/
        res_mipmap = os.path.join(ANDROID_RES, f"mipmap-{dens}")
        os.makedirs(res_mipmap, exist_ok=True)
        sq_img.save(os.path.join(res_mipmap, "ic_launcher.png"), "PNG")
        round_img.save(os.path.join(res_mipmap, "ic_launcher_round.png"), "PNG")


def generate_windows_assets(master_black):
    """Generates Windows ICO (multi-size), setup wizard BMPs, and tray icon."""
    bbox = master_black.getbbox()
    glyph_crop = master_black.crop(bbox)

    ico_sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256]
    ico_images = []

    for s in ico_sizes:
        # 8% padding
        pad = max(1, int(s * 0.08))
        avail = s - (2 * pad)
        gh = avail
        gw = int(glyph_crop.width * (gh / glyph_crop.height))
        scaled = glyph_crop.resize((gw, gh), Image.Resampling.LANCZOS)

        entry = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        ex = (s - gw) // 2
        ey = (s - gh) // 2
        entry.paste(scaled, (ex, ey), mask=scaled.split()[3])
        ico_images.append(entry)

    # Save multi-size app_icon.ico
    app_ico_path = os.path.join(WINDOWS_OUT, "app_icon.ico")
    ico_images[-1].save(
        app_ico_path,
        format="ICO",
        sizes=[(im.width, im.height) for im in ico_images],
        append_images=ico_images[:-1],
    )

    # Copy to windows/runner/resources/app_icon.ico
    shutil.copy2(app_ico_path, os.path.join(WINDOWS_RES, "app_icon.ico"))

    # Also save 256x256 PNG for MSIX / tile manifests
    ico_images[-1].save(os.path.join(WINDOWS_OUT, "app_icon_256.png"), "PNG")

    # Tray icon (16, 24, 32)
    tray_images = [im for im in ico_images if im.width in [16, 24, 32]]
    tray_ico_path = os.path.join(WINDOWS_OUT, "tray_icon.ico")
    tray_images[-1].save(
        tray_ico_path,
        format="ICO",
        sizes=[(im.width, im.height) for im in tray_images],
        append_images=tray_images[:-1],
    )

    # Inno Setup wizard images (24-bit BMP)
    # Left panel: 164x314, white background, glyph centered at upper third
    wiz_img = Image.new("RGB", (164, 314), COLOR_LIGHT_BG)
    w_gh = 96
    w_gw = int(glyph_crop.width * (w_gh / glyph_crop.height))
    sc_wiz = glyph_crop.resize((w_gw, w_gh), Image.Resampling.LANCZOS)
    wx = (164 - w_gw) // 2
    wy = 48  # upper third
    wiz_img.paste(sc_wiz, (wx, wy), mask=sc_wiz.split()[3])
    wiz_img.save(os.path.join(WINDOWS_OUT, "installer_wizard_164x314.bmp"), "BMP")

    # Small top-right image: 55x55, white background, glyph centered
    small_img = Image.new("RGB", (55, 55), COLOR_LIGHT_BG)
    s_gh = 38
    s_gw = int(glyph_crop.width * (s_gh / glyph_crop.height))
    sc_small = glyph_crop.resize((s_gw, s_gh), Image.Resampling.LANCZOS)
    sx = (55 - s_gw) // 2
    sy = (55 - s_gh) // 2
    small_img.paste(sc_small, (sx, sy), mask=sc_small.split()[3])
    small_img.save(os.path.join(WINDOWS_OUT, "installer_small_55x55.bmp"), "BMP")


def generate_web_assets(master_black):
    """Generates web favicons (white rounded tile), apple touch icon, PWA icons, and OG image."""
    bbox = master_black.getbbox()
    glyph_crop = master_black.crop(bbox)

    # Favicons (use white tile with black glyph so it remains visible on dark browser tabs)
    fav_sizes = [16, 32, 48]
    fav_images = []
    for s in fav_sizes:
        tile = generate_rounded_tile(master_black, s, radius_ratio=0.22, glyph_ratio=0.62)
        fav_path = os.path.join(WEB_OUT, f"favicon-{s}.png")
        tile.save(fav_path, "PNG")
        fav_images.append(tile)

        # Copy to web/ and site/
        shutil.copy2(fav_path, os.path.join(WEB_DIR, f"favicon-{s}.png"))

    # Save multi-size favicon.ico
    fav_ico_path = os.path.join(WEB_OUT, "favicon.ico")
    fav_images[-1].save(
        fav_ico_path,
        format="ICO",
        sizes=[(im.width, im.height) for im in fav_images],
        append_images=fav_images[:-1],
    )
    shutil.copy2(fav_ico_path, os.path.join(WEB_DIR, "favicon.ico"))
    shutil.copy2(os.path.join(WEB_OUT, "favicon-32.png"), os.path.join(WEB_DIR, "favicon.png"))

    # Apple Touch Icon: 180x180, glyph on white tile, 20% padding
    apple_tile = generate_rounded_tile(master_black, 180, radius_ratio=0.22, glyph_ratio=0.60)
    apple_path = os.path.join(WEB_OUT, "apple-touch-icon.png")
    apple_tile.save(apple_path, "PNG")
    shutil.copy2(apple_path, os.path.join(WEB_DIR, "apple-touch-icon.png"))
    web_icons_dir = os.path.join(WEB_DIR, "icons")
    os.makedirs(web_icons_dir, exist_ok=True)
    shutil.copy2(apple_path, os.path.join(web_icons_dir, "apple-touch-icon.png"))

    # PWA icons: 192 and 512 (purpose "any")
    for s in [192, 512]:
        pwa_tile = generate_rounded_tile(master_black, s, radius_ratio=0.22, glyph_ratio=0.58)
        pwa_path = os.path.join(WEB_OUT, f"icon-{s}.png")
        pwa_tile.save(pwa_path, "PNG")
        shutil.copy2(pwa_path, os.path.join(web_icons_dir, f"Icon-{s}.png"))
        shutil.copy2(pwa_path, os.path.join(web_icons_dir, f"icon-{s}.png"))

    # PWA Maskable icons: 192 and 512 (glyph inside central 60% on solid white)
    for s in [192, 512]:
        mask_tile = Image.new("RGB", (s, s), COLOR_LIGHT_BG)
        m_gh = int(s * 0.52)
        m_gw = int(glyph_crop.width * (m_gh / glyph_crop.height))
        sc_m = glyph_crop.resize((m_gw, m_gh), Image.Resampling.LANCZOS)
        mx = (s - m_gw) // 2
        my = (s - m_gh) // 2
        mask_tile.paste(sc_m, (mx, my), mask=sc_m.split()[3])

        mask_path = os.path.join(WEB_OUT, f"icon-maskable-{s}.png")
        mask_tile.save(mask_path, "PNG")
        shutil.copy2(mask_path, os.path.join(web_icons_dir, f"Icon-maskable-{s}.png"))
        shutil.copy2(mask_path, os.path.join(web_icons_dir, f"icon-maskable-{s}.png"))

    # SVG Favicon embedding the master glyph cleanly
    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="100%" height="100%">
  <rect width="1024" height="1024" rx="220" fill="#FFFFFF"/>
  <!-- Anchor logo glyph master -->
  <image href="data:image/png;base64,{_get_base64(os.path.join(ASSETS_DIR, 'glyph_black.png'))}" x="226" y="178" width="572" height="668"/>
</svg>'''
    with open(os.path.join(WEB_OUT, "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)
    with open(os.path.join(WEB_DIR, "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)

    # Open Graph Image: 1200x630 white background, glyph + wordmark "anchor" + tagline
    og_img = Image.new("RGB", (1200, 630), COLOR_LIGHT_BG)
    draw_og = ImageDraw.Draw(og_img)

    og_gh = 160
    og_gw = int(glyph_crop.width * (og_gh / glyph_crop.height))
    sc_og = glyph_crop.resize((og_gw, og_gh), Image.Resampling.LANCZOS)

    font_og_title = ImageFont.truetype(FONT_SEMIBOLD, 108)
    font_og_tagline = ImageFont.truetype(FONT_REGULAR, 40)

    title_bbox = draw_og.textbbox((0, 0), "anchor", font=font_og_title)
    title_w = title_bbox[2] - title_bbox[0]
    title_h = title_bbox[3] - title_bbox[1]

    tagline_str = "Plan it. Do it. Anchor it."
    tagline_bbox = draw_og.textbbox((0, 0), tagline_str, font=font_og_tagline)
    tagline_w = tagline_bbox[2] - tagline_bbox[0]
    tagline_h = tagline_bbox[3] - tagline_bbox[1]

    # Center lockup vertically:
    # Row 1: [Glyph 160h] [28px gap] [anchor]
    # Row 2: Tagline (centered under lockup, 24px below)
    lockup_gap = 28
    lockup_w = og_gw + lockup_gap + title_w
    total_block_h = og_gh + 32 + tagline_h

    block_top = (630 - total_block_h) // 2
    row1_left = (1200 - lockup_w) // 2

    og_img.paste(sc_og, (row1_left, block_top), mask=sc_og.split()[3])
    draw_og.text(
        (row1_left + og_gw + lockup_gap, block_top + (og_gh - title_h) // 2 - title_bbox[1]),
        "anchor",
        font=font_og_title,
        fill=COLOR_GLYPH_BLACK
    )

    tagline_left = (1200 - tagline_w) // 2
    tagline_top = block_top + og_gh + 32
    draw_og.text(
        (tagline_left, tagline_top),
        tagline_str,
        font=font_og_tagline,
        fill=(113, 113, 122) # #71717A textSecondary
    )

    og_path = os.path.join(WEB_OUT, "og-image.png")
    og_img.save(og_path, "PNG")
    shutil.copy2(og_path, os.path.join(WEB_DIR, "og-image.png"))


def _get_base64(filepath):
    import base64
    with open(filepath, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def generate_static_landing_site():
    """Generates the static landing folder site/ with self-contained index.html and assets."""
    os.makedirs(SITE_OUT, exist_ok=True)

    # Copy web assets to site/
    for fn in [
        "favicon.ico", "favicon-16.png", "favicon-32.png", "favicon-48.png",
        "favicon.svg", "apple-touch-icon.png", "icon-192.png", "icon-512.png",
        "icon-maskable-192.png", "icon-maskable-512.png", "og-image.png"
    ]:
        src = os.path.join(WEB_OUT, fn)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(SITE_OUT, fn))

    shutil.copy2(os.path.join(ASSETS_DIR, "glyph_black.png"), os.path.join(SITE_OUT, "glyph_black.png"))
    shutil.copy2(os.path.join(ASSETS_DIR, "glyph_white.png"), os.path.join(SITE_OUT, "glyph_white.png"))

    index_html = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Anchor - Personal Anti-Procrastination & Productivity App</title>
  <meta name="description" content="Plan it. Do it. Anchor it. Personal anti-procrastination, academics, expenses, and habit tracking.">
  <meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#0E0E10" media="(prefers-color-scheme: dark)">
  <link rel="icon" href="favicon.ico" sizes="any">
  <link rel="icon" type="image/svg+xml" href="favicon.svg">
  <link rel="apple-touch-icon" href="apple-touch-icon.png">
  <link rel="manifest" href="manifest.webmanifest">
  <meta property="og:title" content="Anchor">
  <meta property="og:description" content="Plan it. Do it. Anchor it. Personal anti-procrastination, academics, expenses, and habits.">
  <meta property="og:image" content="og-image.png">
  <style>
    :root {
      --bg: #FFFFFF;
      --card: #F4F4F5;
      --border: #E4E4E7;
      --text: #111111;
      --muted: #71717A;
      --btn-bg: #111111;
      --btn-text: #FFFFFF;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0E0E10;
        --card: #17171A;
        --border: #27272A;
        --text: #F4F4F5;
        --muted: #A1A1AA;
        --btn-bg: #F4F4F5;
        --btn-text: #111111;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Inter, Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
      text-align: center;
    }
    .container { max-width: 640px; margin: 0 auto; }
    .logo-img { width: 96px; height: 96px; margin-bottom: 24px; }
    h1 { font-size: 40px; font-weight: 700; letter-spacing: -1px; margin-bottom: 12px; }
    p.tagline { font-size: 20px; color: var(--muted); margin-bottom: 36px; }
    .buttons { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; margin-bottom: 48px; }
    .btn {
      display: inline-block;
      background: var(--btn-bg);
      color: var(--btn-text);
      padding: 14px 28px;
      border-radius: 9999px;
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
      transition: opacity 0.15s ease;
    }
    .btn:hover { opacity: 0.9; }
    footer { font-size: 13px; color: var(--muted); }
  </style>
</head>
<body>
  <div class="container">
    <picture>
      <source srcset="glyph_white.png" media="(prefers-color-scheme: dark)">
      <img src="glyph_black.png" alt="Anchor Logo" class="logo-img">
    </picture>
    <h1>anchor</h1>
    <p class="tagline">Plan it. Do it. Anchor it.</p>
    <div class="buttons">
      <!-- TODO: Replace with official releases -->
      <a href="#" class="btn">Download for Android (APK)</a>
      <a href="#" class="btn">Download for Windows (EXE)</a>
    </div>
    <footer>
      &copy; 2026 Anchor. Personal anti-procrastination, academics, expenses, and habit tracking.
    </footer>
  </div>
</body>
</html>
'''
    with open(os.path.join(SITE_OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(index_html)

    manifest_web = '''{
  "name": "Anchor",
  "short_name": "Anchor",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0E0E10",
  "theme_color": "#0E0E10",
  "description": "Plan it. Do it. Anchor it.",
  "icons": [
    {
      "src": "icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}'''
    with open(os.path.join(SITE_OUT, "manifest.webmanifest"), "w", encoding="utf-8") as f:
        f.write(manifest_web)


def generate_contact_sheet(master_black, master_white):
    """Generates assets/branding/_preview.png showing all branding applications."""
    sheet_w, sheet_h = 1200, 800
    sheet = Image.new("RGB", (sheet_w, sheet_h), (240, 240, 242))
    draw = ImageDraw.Draw(sheet)
    font_header = ImageFont.truetype(FONT_SEMIBOLD, 28)
    font_label = ImageFont.truetype(FONT_REGULAR, 14)

    draw.text((32, 24), "Anchor - Brand Assets Contact Sheet & Quality Verification", font=font_header, fill=(17, 17, 17))

    # 1. Adaptive Icon Masked Previews (Circle, Squircle, Rounded Square)
    # Circle mask
    circ_mask = Image.new("L", (140, 140), 0)
    ImageDraw.Draw(circ_mask).ellipse([(0, 0), (139, 139)], fill=255)

    # Squircle mask (superellipse approx)
    squircle_mask = Image.new("L", (140, 140), 0)
    ImageDraw.Draw(squircle_mask).rounded_rectangle([(0, 0), (139, 139)], radius=42, fill=255)

    # Rounded Square mask
    rsq_mask = Image.new("L", (140, 140), 0)
    ImageDraw.Draw(rsq_mask).rounded_rectangle([(0, 0), (139, 139)], radius=24, fill=255)

    fg_src = Image.open(os.path.join(ANDROID_OUT, "ic_launcher_foreground.png")).resize((140, 140), Image.Resampling.LANCZOS)
    bg_tile = Image.new("RGB", (140, 140), COLOR_LIGHT_BG)
    bg_tile.paste(fg_src, (0, 0), mask=fg_src.split()[3])

    def mask_img(img, m):
        res = Image.new("RGBA", img.size, (0, 0, 0, 0))
        res.paste(img, (0, 0), mask=m)
        return res

    circ_p = mask_img(bg_tile, circ_mask)
    squir_p = mask_img(bg_tile, squircle_mask)
    rsq_p = mask_img(bg_tile, rsq_mask)

    sheet.paste(circ_p, (40, 90), mask=circ_p.split()[3])
    draw.text((40, 240), "Adaptive: Circle", font=font_label, fill=(100, 100, 100))

    sheet.paste(squir_p, (210, 90), mask=squir_p.split()[3])
    draw.text((210, 240), "Adaptive: Squircle", font=font_label, fill=(100, 100, 100))

    sheet.paste(rsq_p, (380, 90), mask=rsq_p.split()[3])
    draw.text((380, 240), "Adaptive: Rounded", font=font_label, fill=(100, 100, 100))

    # 2. Android 13 Monochrome on Dark Wallpaper
    mono_bg = Image.new("RGB", (140, 140), (32, 44, 40)) # dark wallpaper tint
    mono_fg = Image.open(os.path.join(ANDROID_OUT, "ic_launcher_monochrome.png")).resize((140, 140), Image.Resampling.LANCZOS)
    # Tint monochrome to light green themed tint
    tint_mono = Image.new("RGB", (140, 140), (200, 240, 220))
    mono_bg.paste(tint_mono, (0, 0), mask=mono_fg.split()[3])
    mono_masked = mask_img(mono_bg, circ_mask)
    sheet.paste(mono_masked, (550, 90), mask=mono_masked.split()[3])
    draw.text((550, 240), "Android 13 Themed", font=font_label, fill=(100, 100, 100))

    # 3. Notification Small Icon on dark status bar
    notif_bg = Image.new("RGB", (140, 140), (17, 17, 17))
    notif_fg = Image.open(os.path.join(ANDROID_OUT, "ic_stat_anchor_xxhdpi.png")).resize((48, 48), Image.Resampling.LANCZOS)
    notif_bg.paste(notif_fg, ((140 - 48)//2, (140 - 48)//2), mask=notif_fg.split()[3])
    sheet.paste(notif_bg, (720, 90))
    draw.text((720, 240), "Status Bar Icon", font=font_label, fill=(100, 100, 100))

    # 4. ICO Sizes (16, 32, 256)
    ico_256 = Image.open(os.path.join(WINDOWS_OUT, "app_icon_256.png")).resize((140, 140), Image.Resampling.LANCZOS)
    sheet.paste(ico_256, (890, 90), mask=ico_256.split()[3])
    draw.text((890, 240), "Windows ICO (256)", font=font_label, fill=(100, 100, 100))

    # Row 2: Splash Light, Splash Dark, Favicon Light/Dark, Feature Graphic
    # Splash Light (400x240)
    sp_light = Image.new("RGB", (280, 200), COLOR_LIGHT_BG)
    sp_l_glyph = master_black.resize((64, int(64 * 661 / 564)), Image.Resampling.LANCZOS)
    sp_light.paste(sp_l_glyph, ((280 - sp_l_glyph.width)//2, (200 - sp_l_glyph.height)//2), mask=sp_l_glyph.split()[3])
    sheet.paste(sp_light, (40, 280))
    draw.text((40, 490), "Splash Screen: Light Mode", font=font_label, fill=(100, 100, 100))

    # Splash Dark (400x240)
    sp_dark = Image.new("RGB", (280, 200), COLOR_DARK_BG)
    sp_d_glyph = master_white.resize((64, int(64 * 661 / 564)), Image.Resampling.LANCZOS)
    sp_dark.paste(sp_d_glyph, ((280 - sp_d_glyph.width)//2, (200 - sp_d_glyph.height)//2), mask=sp_d_glyph.split()[3])
    sheet.paste(sp_dark, (350, 280))
    draw.text((350, 490), "Splash Screen: Dark Mode", font=font_label, fill=(100, 100, 100))

    # Favicon on white tab & dark tab
    tab_white = Image.new("RGB", (180, 80), (255, 255, 255))
    tab_dark = Image.new("RGB", (180, 80), (32, 33, 36))
    fav_32 = Image.open(os.path.join(WEB_OUT, "favicon-32.png"))

    tab_white.paste(fav_32, (24, 24), mask=fav_32.split()[3])
    ImageDraw.Draw(tab_white).text((68, 30), "Anchor", font=font_label, fill=(32, 33, 36))

    tab_dark.paste(fav_32, (24, 24), mask=fav_32.split()[3])
    ImageDraw.Draw(tab_dark).text((68, 30), "Anchor", font=font_label, fill=(240, 240, 240))

    sheet.paste(tab_white, (660, 280))
    draw.text((660, 370), "Favicon: Light Tab", font=font_label, fill=(100, 100, 100))

    sheet.paste(tab_dark, (660, 400))
    draw.text((660, 490), "Favicon: Dark Tab", font=font_label, fill=(100, 100, 100))

    # Row 3: Feature Graphic (scaled to 400x195)
    feat = Image.open(os.path.join(ANDROID_OUT, "feature_graphic_1024x500.png")).resize((480, 234), Image.Resampling.LANCZOS)
    sheet.paste(feat, (40, 520))
    draw.text((40, 765), "Play Store Feature Graphic (1024x500)", font=font_label, fill=(100, 100, 100))

    # Open Graph Image (scaled to 480x252)
    og = Image.open(os.path.join(WEB_OUT, "og-image.png")).resize((480, 252), Image.Resampling.LANCZOS)
    sheet.paste(og, (550, 520))
    draw.text((550, 780), "Open Graph Social Preview (1200x630)", font=font_label, fill=(100, 100, 100))

    sheet.save(os.path.join(ASSETS_DIR, "_preview.png"), "PNG")


def self_check_and_verify():
    """Runs programmatic assertions on generated outputs."""
    print("=" * 70)
    print("RUNNING SELF-CHECK ON GENERATED BRAND ASSETS")
    print("=" * 70)

    # 1. Check core assets
    for name in ["glyph_black.png", "glyph_white.png", "tile_light_1024.png", "tile_dark_1024.png"]:
        path = os.path.join(ASSETS_DIR, name)
        assert os.path.exists(path), f"Missing {name}"
        im = Image.open(path)
        assert im.size == (1024, 1024), f"{name} size {im.size} != (1024, 1024)"
        print(f"[OK] {name:<24} size={im.size} mode={im.mode}")

    # 2. Check Android adaptive foreground safe zone (must fit inside 66% circle: radius 142.56px)
    fg_path = os.path.join(ANDROID_OUT, "ic_launcher_foreground.png")
    im_fg = Image.open(fg_path)
    assert im_fg.size == (432, 432), f"Foreground size {im_fg.size} != (432, 432)"
    arr_fg = np.array(im_fg)[:, :, 3]
    y_idx, x_idx = np.where(arr_fg > 10)
    x_coords = x_idx - 216.0
    y_coords = y_idx - 216.0
    radii = np.sqrt(x_coords**2 + y_coords**2)
    max_radius = radii.max()
    safe_zone_limit = 432 * 0.33
    assert max_radius <= safe_zone_limit, f"Foreground glyph exceeds 66% safe zone! {max_radius:.2f} > {safe_zone_limit:.2f}"
    print(f"[OK] ic_launcher_foreground.png: max radius {max_radius:.2f} px <= safe zone limit {safe_zone_limit:.2f} px")

    # 3. Check Notification Small Icons are pure white RGB with alpha
    for dens in ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]:
        notif_path = os.path.join(ANDROID_OUT, f"ic_stat_anchor_{dens}.png")
        im_n = Image.open(notif_path)
        arr_n = np.array(im_n)
        alpha_mask = arr_n[:, :, 3] > 0
        rgb_channels = arr_n[alpha_mask][:, :3]
        assert np.all(rgb_channels == 255), f"Notification icon {dens} contains non-white pixels!"
        print(f"[OK] ic_stat_anchor_{dens}.png size={im_n.size} pure white with alpha: PASS")

    # 4. Check Windows ICO contains all required resolutions
    ico_path = os.path.join(WINDOWS_OUT, "app_icon.ico")
    assert os.path.exists(ico_path), "Missing app_icon.ico"
    im_ico = Image.open(ico_path)
    expected_sizes = {16, 20, 24, 32, 40, 48, 64, 128, 256}
    found_sizes = set()
    # Read icon directory from header
    with open(ico_path, "rb") as f:
        data = f.read()
        reserved, ico_type, count = struct.unpack_from("<HHH", data, 0)
        assert ico_type == 1, "Not an ICO file"
        for i in range(count):
            w = data[6 + i * 16]
            h = data[7 + i * 16]
            w = 256 if w == 0 else w
            h = 256 if h == 0 else h
            found_sizes.add(w)
    assert expected_sizes.issubset(found_sizes), f"ICO missing sizes: {expected_sizes - found_sizes}"
    print(f"[OK] app_icon.ico contains all required sizes: {sorted(list(found_sizes))}")

    # 5. Check BMPs are valid uncompressed BMP
    for bmp_name, expected_s in [("installer_wizard_164x314.bmp", (164, 314)), ("installer_small_55x55.bmp", (55, 55))]:
        bmp_path = os.path.join(WINDOWS_OUT, bmp_name)
        assert os.path.exists(bmp_path)
        im_b = Image.open(bmp_path)
        assert im_b.size == expected_s, f"{bmp_name} size {im_b.size} != {expected_s}"
        assert im_b.format == "BMP", f"{bmp_name} not BMP format"
        print(f"[OK] {bmp_name} size={im_b.size} format=BMP")

    print("=" * 70)
    print("ALL BRAND ASSET VERIFICATIONS PASSED (100% GREEN)")
    print("=" * 70)


def main():
    ensure_dirs()
    print("Cleaning source masters...")
    master_black, master_white, master_mono, tile_light = clean_source_masters()

    print("Generating core root assets...")
    generate_core_assets(master_black, master_white)

    print("Generating Android assets & density drawables...")
    generate_android_assets(master_black, master_white)

    print("Generating Windows desktop & installer assets...")
    generate_windows_assets(master_black)

    print("Generating Web favicons, PWA icons, and OG preview...")
    generate_web_assets(master_black)

    print("Generating static landing site...")
    generate_static_landing_site()

    print("Generating visual preview contact sheet...")
    generate_contact_sheet(master_black, master_white)

    print("Running self-check...")
    self_check_and_verify()


if __name__ == "__main__":
    main()
