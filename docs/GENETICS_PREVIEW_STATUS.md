# Genetics preview baseline — 17 October 2026

Status: baseline verified; genetics implementation awaits the referenced product specifications. No Genetics Preview APK exists yet.

## Source and safety

Cloned and fetched `kavemankai/Kaijustomp`. The clean starting checkout, remote `feature/persistent-streamed-world`, and PR #18 head all resolve to `35dc25b95d05322459e70e39ea046dc6a3f9085d`. Created local branch `feature/nine-form-genetics-preview` from that commit. PR #18 remains a dependency; no merge, reset, installation, release replacement or gameplay change was performed.

Read CODEX_HANDOVER, WORLD_OBJECTIVES, WORLD_STREAMING, EVOLUTION_PROGRESSION, ARCHITECTURE, BUILDING, the regression runner and Android workflow. Historical suite counts in some documents are superseded by current discovery: 25 suites. The active entry is BeachDemo; current RESTART clears the world. Genetics and a new-organism path have not been implemented.

## Reproduced verification

Windows desktop headless, official `4.5.stable.official.876b29033`, Python standard-library runner:

```text
python scripts/ci/run_regressions.py --godot <Godot_v4.5-stable_win64_console.exe> --output build/genetics-baseline
```

Import, 60-frame launch and all **25/25 suites pass**, with zero failed results. Tested source is exactly the starting commit above. Machine-readable results: [validation/genetics-baseline/windows-regressions.json](validation/genetics-baseline/windows-regressions.json). Full local logs remain under ignored `build/genetics-baseline/`. This is baseline evidence, not evidence of new genetics features or physical Android performance.

Independently downloaded World Preview #231 to ignored `build/preserved/Kaijustomp-231-3734363-debug.apk`:

- Size: 28,112,447 bytes.
- SHA-256: `8e12410ecbd0d2a9ef3878428b5390c64dde69c636277b2417c20081731b22cc`, matching the handoff and repository evidence.
- ZIP CRC passes; AndroidManifest.xml and classes.dex are present.
- Both ARM64 libraries pass the existing ELF 16 KiB alignment verifier.
- Existing `validation/three-missions/android-ci.txt` confirms v2/v3 signing and `com.kavemankai.kaijustomp.worldpreview` for these exact hashed bytes. Signature verification was not independently rerun locally.

## Required inputs

The supplied handoff explicitly requires these documents, which were absent from the attachment, checkout and filename search under Documents:

1. `KaijuStomp_Nine_Form_Evolution_GDD.md`
2. `KaijuStomp_Codex_Nine_Form_Implementation_Spec.md`
3. `kaijustomp_mutation_catalog_500.json`
4. `KaijuStomp_500_Mutation_Integration_Plan.md`

The first two contain approved gradual-evolution rules, the 35-source-gene mappings and test expectations; the catalogue is needed to validate all 500 IDs. The referenced 3x3 EVO1 concept roster is also absent. Requested their location from the user. Do not invent approved gene definitions, source mappings or reference art, or describe this baseline as a completed nine-form implementation.

Next: obtain the missing inputs, implement Gate 1 in small verified commits, then complete Gates 2–7 with actual gameplay, capture and independently packaged release evidence. Existing releases and legacy growth/save contracts must remain preserved.
