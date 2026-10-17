"""Capture streamed-world probe output and sampled process RSS (desktop/CI evidence)."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def rss_bytes(pid):
    try:
        import psutil
        parent = psutil.Process(pid)
        # Godot's Windows console launcher owns a separate engine child.
        return sum(p.memory_info().rss for p in [parent, *parent.children(recursive=True)] if p.is_running())
    except ImportError:
        try:
            for line in Path(f"/proc/{pid}/status").read_text().splitlines():
                if line.startswith("VmRSS:"):
                    return int(line.split()[1]) * 1024
        except (OSError, ValueError):
            pass
    except Exception:
        pass
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--rendered", action="store_true")
    args = parser.parse_args()
    out = ROOT / "build/world-profile"
    out.mkdir(parents=True, exist_ok=True)
    label = "rendered" if args.rendered else "headless"
    command = [str(Path(args.godot).resolve())]
    if not args.rendered:
        command.append("--headless")
    command += ["--path", str(ROOT), "--script", "res://scripts/ci/profile_streaming.gd"]
    peak_rss = 0
    with (out / f"{label}.log").open("w", encoding="utf-8") as log:
        proc = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, cwd=ROOT)
        deadline = time.monotonic() + 180
        while proc.poll() is None:
            peak_rss = max(peak_rss, rss_bytes(proc.pid) or 0)
            if time.monotonic() > deadline:
                proc.kill()
                raise SystemExit("World profiler timed out")
            time.sleep(.1)
    text = (out / f"{label}.log").read_text(encoding="utf-8")
    if proc.returncode or "SCRIPT ERROR" in text or "ERROR:" in text:
        print(text)
        return 1
    report_path = out / f"{label}.json"
    report = json.loads(report_path.read_text())
    report.update(process_peak_rss_mib=round(peak_rss / 1048576, 2) if peak_rss else None,
                  platform=os.name, mode=label)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
