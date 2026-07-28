from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"D:\Downloads\Nuego logo rutio Sin fondo.png")
BRANDING = ROOT / "assets" / "branding"
GENERATED = BRANDING / "generated"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS = ROOT / "ios" / "Runner" / "Assets.xcassets"

BACKGROUND = (207, 166, 131, 255)
SPLASH_BACKGROUND = BACKGROUND
MASTER_VISIBLE_MAX = 840
LAUNCHER_VISIBLE_MAX = 980
ADAPTIVE_VISIBLE_MAX = 760
ADAPTIVE_XML_INSET_PERCENT = 8
ANDROID_SPLASH_VISIBLE_MAX = 102
ANDROID_SPLASH_ICON_VISIBLE_MAX = 173
LAUNCHER_OPTICAL_OFFSET = (10, -8)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Input logo has no visible pixels")
    return bbox


def centered_canvas(
    source: Image.Image,
    size: int,
    visible_max: int,
    *,
    opaque_background: tuple[int, int, int, int] | None = None,
    optical_offset: tuple[int, int] = (0, 0),
) -> Image.Image:
    source = source.convert("RGBA")
    crop = source.crop(alpha_bbox(source))
    scale = visible_max / max(crop.size)
    resized = crop.resize(
        (round(crop.width * scale), round(crop.height * scale)),
        Image.Resampling.LANCZOS,
    )
    background = opaque_background or (0, 0, 0, 0)
    canvas = Image.new("RGBA", (size, size), background)
    x = round((size - resized.width) / 2 + optical_offset[0])
    y = round((size - resized.height) / 2 + optical_offset[1])
    canvas.alpha_composite(resized, (x, y))
    return canvas


def save_png(image: Image.Image, path: Path, *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if opaque:
        image = image.convert("RGB")
    temp_path = path.with_name(f"{path.stem}.tmp{path.suffix}")
    image.save(temp_path, optimize=True)
    temp_path.replace(path)


def write_android_splash_assets(master: Image.Image) -> None:
    densities = {
        "mdpi": 1.0,
        "hdpi": 1.5,
        "xhdpi": 2.0,
        "xxhdpi": 3.0,
        "xxxhdpi": 4.0,
    }
    for density, scale in densities.items():
        folder = ANDROID_RES / f"drawable-{density}"
        save_png(
            centered_canvas(
                master,
                round(168 * scale),
                round(ANDROID_SPLASH_VISIBLE_MAX * scale),
            ),
            folder / "splash_logo.png",
        )
        save_png(
            centered_canvas(
                master,
                round(288 * scale),
                round(ANDROID_SPLASH_ICON_VISIBLE_MAX * scale),
            ),
            folder / "splash_logo_icon.png",
        )


def write_android_adaptive_icon_xml() -> None:
    xml = f"""<?xml version=\"1.0\" encoding=\"utf-8\"?>
<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">
    <background android:drawable=\"@color/ic_launcher_background\" />
    <foreground>
        <inset
            android:drawable=\"@drawable/ic_launcher_foreground\"
            android:inset=\"{ADAPTIVE_XML_INSET_PERCENT}%\" />
    </foreground>
</adaptive-icon>
"""
    for filename in ("ic_launcher.xml", "ic_launcher_round.xml"):
        path = ANDROID_RES / "mipmap-anydpi-v26" / filename
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(xml, encoding="utf-8")


def write_ios_app_icons(icon: Image.Image) -> None:
    appicon = IOS / "AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text())
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        points = float(item["size"].split("x", 1)[0])
        scale = int(item["scale"].replace("x", ""))
        pixels = round(points * scale)
        resized = icon.resize((pixels, pixels), Image.Resampling.LANCZOS)
        save_png(resized, appicon / filename, opaque=True)


def write_ios_launch_images(master: Image.Image) -> None:
    launch = IOS / "LaunchImage.imageset"
    for filename, size in {
        "LaunchImage.png": 168,
        "LaunchImage@2x.png": 336,
        "LaunchImage@3x.png": 504,
    }.items():
        save_png(centered_canvas(master, size, round(size * 0.86)), launch / filename)


def write_metrics(source: Image.Image, master: Image.Image) -> None:
    src_bbox = alpha_bbox(source)
    master_bbox = alpha_bbox(master)
    metrics = {
        "source_path": str(SOURCE),
        "source_size": list(source.size),
        "source_alpha_bbox": list(src_bbox),
        "source_margins": {
            "left": src_bbox[0],
            "top": src_bbox[1],
            "right": source.width - src_bbox[2],
            "bottom": source.height - src_bbox[3],
        },
        "master_size": list(master.size),
        "master_alpha_bbox": list(master_bbox),
        "master_margins": {
            "left": master_bbox[0],
            "top": master_bbox[1],
            "right": master.width - master_bbox[2],
            "bottom": master.height - master_bbox[3],
        },
        "scales": {
            "master_visible_max": MASTER_VISIBLE_MAX,
            "launcher_visible_max": LAUNCHER_VISIBLE_MAX,
            "adaptive_visible_max": ADAPTIVE_VISIBLE_MAX,
            "adaptive_xml_inset_percent": ADAPTIVE_XML_INSET_PERCENT,
            "android_splash_visible_max": ANDROID_SPLASH_VISIBLE_MAX,
            "android_splash_icon_visible_max": ANDROID_SPLASH_ICON_VISIBLE_MAX,
            "launcher_optical_offset": list(LAUNCHER_OPTICAL_OFFSET),
        },
    }
    (GENERATED / "branding_metrics.json").write_text(
        json.dumps(metrics, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    BRANDING.mkdir(parents=True, exist_ok=True)
    GENERATED.mkdir(parents=True, exist_ok=True)

    source_copy = BRANDING / "rutio_logo_source_1254.png"
    shutil.copyfile(SOURCE, source_copy)

    splash_only = "--android-splash-only" in sys.argv[1:]
    launcher_only = "--launcher-icons-only" in sys.argv[1:]
    source = Image.open(source_copy).convert("RGBA")

    if splash_only:
        master = Image.open(BRANDING / "rutio_logo_master_1024.png").convert("RGBA")
        write_android_splash_assets(master)
        write_metrics(source, master)
        return

    master = centered_canvas(source, 1024, MASTER_VISIBLE_MAX)
    android_icon = centered_canvas(
        source,
        1024,
        LAUNCHER_VISIBLE_MAX,
        opaque_background=BACKGROUND,
        optical_offset=LAUNCHER_OPTICAL_OFFSET,
    )
    ios_icon = centered_canvas(
        source,
        1024,
        LAUNCHER_VISIBLE_MAX,
        opaque_background=BACKGROUND,
        optical_offset=LAUNCHER_OPTICAL_OFFSET,
    )
    adaptive_foreground = centered_canvas(
        source,
        1024,
        ADAPTIVE_VISIBLE_MAX,
        optical_offset=LAUNCHER_OPTICAL_OFFSET,
    )

    save_png(android_icon, GENERATED / "rutio_logo_android_icon_1024.png", opaque=True)
    save_png(ios_icon, GENERATED / "rutio_logo_ios_icon_1024.png", opaque=True)
    save_png(adaptive_foreground, GENERATED / "rutio_logo_adaptive_foreground_1024.png")

    if launcher_only:
        write_android_adaptive_icon_xml()
        write_metrics(source, master)
        return

    save_png(master, BRANDING / "rutio_logo_master_1024.png")
    save_png(master.resize((512, 512), Image.Resampling.LANCZOS), GENERATED / "rutio_logo_512.png")

    write_android_splash_assets(master)
    write_android_adaptive_icon_xml()
    write_ios_app_icons(ios_icon)
    write_ios_launch_images(master)
    write_metrics(source, master)


if __name__ == "__main__":
    main()
