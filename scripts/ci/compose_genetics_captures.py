"""Compose actual same-camera Godot crops. Requires Pillow; never generates artwork."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "build/genetics-captures"
OUT = ROOT / "docs/validation/genetics"
OUT.mkdir(parents=True, exist_ok=True)
FONT = Path("C:/Windows/Fonts/segoeui.ttf")
font = ImageFont.truetype(str(FONT), 19) if FONT.exists() else ImageFont.load_default(size=19)
small = ImageFont.truetype(str(FONT), 15) if FONT.exists() else ImageFont.load_default(size=15)


def sheet(items, columns, filename, title):
    cell_w, cell_h = 360, 270
    rows = (len(items) + columns - 1) // columns
    canvas = Image.new("RGB", (columns * cell_w, rows * cell_h + 85), "#152e35")
    draw = ImageDraw.Draw(canvas)
    draw.text((18, 12), title, font=font, fill="#f1e1bc")
    draw.text((18, 42), "Actual Godot 4.5 viewport crops | same camera, light and physical scale 1x | ground prototypes", font=small, fill="#a9c9c4")
    for index, (stem, label) in enumerate(items):
        x, y = (index % columns) * cell_w, 85 + (index // columns) * cell_h
        image = Image.open(SOURCE / (stem + ".png")).convert("RGB")
        crop = image.crop((120, 440, 380, 600)).resize((340, 209), Image.Resampling.LANCZOS)
        canvas.paste(crop, (x + 10, y + 45))
        draw.text((x + 12, y + 8), label[:39], font=font if len(label) < 30 else small, fill="white")
    canvas.save(OUT / filename, optimize=True)


forms = ["reptile", "biomass", "snake", "bird", "crab", "spider", "ape", "worm", "mole"]
sheet([(f, f.capitalize()) for f in forms], 3, "nine-forms.png", "KAIJUSTOMP / NINE EVO1 FAMILY PROOFS")
sheet([(f, f.replace("_", " + ").title()) for f in ["reptile_bird", "ape_crab", "worm_mole"]], 3, "three-hybrids.png", "KAIJUSTOMP / THREE EXPRESSED HYBRIDS")
catalog = json.loads((ROOT / "data/evolution/kaijustomp_mutation_catalog_500.json").read_text(encoding="utf-8"))
names = {row["id"]: row["name"] for row in catalog["entries"]}
ids = sorted(int(p.stem.split("_")[1]) for p in SOURCE.glob("source_*.png"))
sheet([(f"source_{n:03d}", f"#{n} {names[n]}") for n in ids], 5, "35-source-traits.png", "KAIJUSTOMP / CURATED 35 SOURCE TRAIT PROOFS")
for name in ["draft", "lineage", "reptile_bird", "ape_crab", "worm_mole"]:
    Image.open(SOURCE / f"{name}.png").save(OUT / f"{name}.png", optimize=True)
print(f"Composed {len(ids)} source traits, nine forms, three hybrids and portrait UI in {OUT}")
