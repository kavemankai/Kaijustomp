# Actual Godot polish evidence

These are Godot 4.5 engine frames, not concept art. Raw PNGs, SHA256 manifest and automated coverage CSV are retained with the Actions polish-evidence artifact.

565 required frames: 108 gameplay + 108 inspection growth views, 243 generic tiers, 48 hybrid views, 41 source organs, 17 traversal/UI frames.

Inspection cameras help assess anatomy; gameplay captures use the live camera. Action fixtures and QA growth do not establish natural progression, phone controls or Android FPS.

| Evidence | Contact sheet |
|---|---|
| Nine forms | [nine-forms](nine-forms.jpg) |
| Growth 0/6/12/18 | [growth-36](growth-36.jpg) |
| Eight hybrid routes | [hybrids-24](hybrids-24.jpg) |
| 41 executable sources | [sources-41](sources-41.jpg) |
| Traversal physics states | [traversal](traversal.jpg) |
| Before/after 1555b33 | [baseline-comparison](baseline-comparison.jpg) |
| Reptile I/II/III | [upgrades-reptile](upgrades-reptile.jpg) |
| Biomass I/II/III | [upgrades-biomass](upgrades-biomass.jpg) |
| Snake I/II/III | [upgrades-snake](upgrades-snake.jpg) |
| Bird I/II/III | [upgrades-bird](upgrades-bird.jpg) |
| Crab I/II/III | [upgrades-crab](upgrades-crab.jpg) |
| Spider I/II/III | [upgrades-spider](upgrades-spider.jpg) |
| Ape I/II/III | [upgrades-ape](upgrades-ape.jpg) |
| Worm I/II/III | [upgrades-worm](upgrades-worm.jpg) |
| Mole I/II/III | [upgrades-mole](upgrades-mole.jpg) |

[20:9 mutation cards](ui_draft_20_9.jpg) · [Capture manifest](capture-manifest.json)

Reproduce: Godot 4.5 --path . --rendering-method gl_compatibility --script res://scripts/ci/capture_polish.gd; python scripts/ci/compose_polish_captures.py.
