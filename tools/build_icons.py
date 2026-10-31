"""Generate Eclipse Arena OS launcher icons from approved katana/eclipse artwork."""
from __future__ import annotations
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "launcher.webp"
FILES = [
    (ROOT / "assets" / "icon.png", (192, 192)),
    (ROOT / "assets" / "icon_adaptive.png", (432, 432)),
    (ROOT / "assets" / "icon_background.png", (432, 432)),
]
ICO = ROOT / "assets" / "EclipseArena.ico"


def build() -> None:
    with Image.open(SRC) as im:
        icon = im.convert("RGBA")
    if icon.size != (192, 192):
        raise ValueError("Expected 192x192 launcher.webp")
    icon.save(FILES[0][0])
    foreground = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    foreground.alpha_composite(icon.resize((288, 288), Image.Resampling.LANCZOS), (72, 72))
    foreground.save(FILES[1][0])
    Image.new("RGBA", (432, 432), (6, 7, 19, 255)).save(FILES[2][0])
    icon.convert("RGB").resize((256, 256), Image.Resampling.LANCZOS).save(
        ICO, format="ICO", sizes=[(16, 16), (24, 24), (32, 32),
                                 (48, 48), (64, 64), (128, 128), (256, 256)])


def verify() -> None:
    for path, size in FILES:
        with Image.open(path) as im:
            assert im.size == size, f"{path}: expected {size}, got {im.size}"
    with Image.open(ICO) as im:
        assert (16, 16) in im.ico.sizes()
        assert (256, 256) in im.ico.sizes()


if __name__ == "__main__":
    if "--verify" not in sys.argv:
        build()
    verify()
