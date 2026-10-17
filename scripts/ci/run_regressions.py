"""Run every gameplay suite with Godot 4.5; retain logs and fail on engine errors."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
ERROR = re.compile(r"SCRIPT ERROR|Parse Error|TEST FAILED|Invalid call|Invalid access|^ERROR:", re.M)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 4.5 console executable")
    parser.add_argument("--output", default="build/regressions")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--suite", action="append", help="Run named suites only; CI defaults to discovering all suites")
    args = parser.parse_args()
    out = ROOT / args.output
    out.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output([args.godot, "--headless", "--version"], text=True).strip()
    if not version.startswith("4.5.stable"):
        parser.error(f"Expected 4.5.stable, got {version}")
    jobs = [("import", ["--editor", "--quit"]), ("launch", ["--quit-after", "60"])]
    jobs += [(p.stem, ["--script", "res://" + p.relative_to(ROOT).as_posix()])
             for p in sorted((ROOT / "scripts/ci").glob("test_*.gd"))
             if not args.suite or p.stem in args.suite]
    results = []
    for name, flags in jobs:
        start = time.monotonic()
        try:
            proc = subprocess.run([args.godot, "--headless", "--path", str(ROOT), *flags],
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  timeout=args.timeout, encoding="utf-8", errors="replace")
            log, code = proc.stdout, proc.returncode
        except subprocess.TimeoutExpired as exc:
            log = (exc.stdout or b"").decode("utf-8", errors="replace") + "\nTIMEOUT\n"
            code = -1
        passed = code == 0 and not ERROR.search(log) and (not name.startswith("test_") or "TEST PASSED" in log)
        (out / f"{name}.log").write_text(log, encoding="utf-8")
        results.append(dict(name=name, passed=passed, exit_code=code, seconds=round(time.monotonic()-start, 3)))
        print(f"{'PASS' if passed else 'FAIL'} {name} ({results[-1]['seconds']}s)", flush=True)
        if not passed:
            print(log[-6000:], flush=True)
        if name == "import" and not passed:
            break
    report = dict(godot=version, suites=sum(r['name'].startswith('test_') for r in results), results=results)
    (out / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if len(results) == len(jobs) and all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
