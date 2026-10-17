# World implementation verification

Status: implementation in progress. No new APK or Android performance acceptance is claimed yet.

Baseline verified on2026-10-17: integration/stable-baseline `00eb61e`, gameplay source `317743c`, official Godot4.5.stable.official.876b29033 on Windows. Import,60-frame launch and all16 existing suites pass. Raw local logs: ignored `build/baseline`.

Baseline desktop headless CPU probe:923.193ms construction,2076 startup nodes,47.99MiB engine static allocation. Idle scripted update medians0.435–0.520ms and p95 0.506–0.692ms across E0/E5/E16/E22/E28/E34/E55/E80/E120 in this run. These exclude GPU submission, real frame pacing and total process memory; they establish no Android FPS claim.

The first integrated streaming/dynamic passes retain all16 suites successfully after explicit authored activation. New generation, persistence and long-travel suites are being exercised. First-pass findings included incomplete coastal sampling in the district test and noisy JSON error logging during intentional corrupt-save recovery; fixes are under validation.

Final evidence will include deterministic visitation order, roads/seams, long coastal and inland physical travel, damage/destruction/reward persistence, save/reload/migration/recovery, responder routing/offscreen materialisation, giant camera/collision, bounded ownership, rendered traversal and verified Android packaging. Physical phone installation, sustained frame timing, thermals and multitouch remain separate device checks.
