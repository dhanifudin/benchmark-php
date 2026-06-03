#!/usr/bin/env python3
"""Aggregates raw benchmark JSON results into processed statistics."""
import json, glob, statistics
from collections import defaultdict
from datetime import datetime, timezone

def main():
    files = glob.glob("results/raw/*.json")
    groups = defaultdict(list)

    for f in sorted(files):
        d = json.load(open(f))
        env = d["environment"]
        wl = d["workload"]
        key = (
            env.get("framework", ""),
            env.get("runtime", ""),
            env["runtime_config"],
            wl["scenario"],
            env.get("code_form", ""),
            wl.get("connections", 32),
        )
        groups[key].append(d)

    rows = []
    for key in sorted(groups.keys()):
        reps = groups[key]
        fw, rt, rtc, sc, cf, conns = key
        rps_vals = [r["metrics"]["requests_per_second"] for r in reps]
        p50_vals = [r["metrics"]["latency_p50_ms"] for r in reps]
        p99_raw = [r["metrics"].get("latency_p99_ms") for r in reps if r["metrics"].get("latency_p99_ms")]
        err_total = sum(r["metrics"]["error_count"] for r in reps)

        median_rps = round(statistics.median(rps_vals), 1) if len(rps_vals) >= 2 else rps_vals[0]
        stdev_rps = round(statistics.stdev(rps_vals), 2) if len(rps_vals) >= 2 else None
        rsd_pct = round((stdev_rps / median_rps * 100), 2) if stdev_rps and median_rps > 0 else None
        iqr_rps = None
        if len(rps_vals) >= 4:
            sv = sorted(rps_vals)
            q1 = statistics.median(sv[:len(sv)//2])
            q3 = statistics.median(sv[len(sv)//2+1:] if len(sv)%2==1 else sv[len(sv)//2:])
            iqr_rps = round(q3 - q1, 2)

        median_p50 = round(statistics.median(p50_vals), 2) if len(p50_vals) >= 2 else p50_vals[0]
        median_p99 = round(statistics.median(p99_raw), 2) if len(p99_raw) >= 2 else (p99_raw[0] if p99_raw else None)

        rows.append({
            "framework": fw,
            "runtime": rt,
            "runtime_config": rtc,
            "scenario": sc,
            "code_form": cf,
            "connections": conns,
            "repetitions": len(rps_vals),
            "median_rps": median_rps,
            "stdev_rps": stdev_rps,
            "rsd_pct": rsd_pct,
            "iqr_rps": iqr_rps,
            "min_rps": round(min(rps_vals), 1),
            "max_rps": round(max(rps_vals), 1),
            "median_p50_ms": median_p50,
            "median_p99_ms": median_p99,
            "error_count_total": err_total,
        })

    with open("results/processed/pilot-aggregated.json", "w") as f:
        json.dump(rows, f, indent=2)

    # Summary stats
    multi_rep = [r for r in rows if r["repetitions"] >= 3]
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    print(f"Generated {ts}: {len(rows)} rows from {len(files)} raw files")
    print(f"Multi-rep cells (n>=3): {len(multi_rep)}")
    if multi_rep:
        rsd_vals = [r["rsd_pct"] for r in multi_rep if r["rsd_pct"]]
        if rsd_vals:
            print(f"  Mean RSD: {statistics.mean(rsd_vals):.1f}%  Median RSD: {statistics.median(rsd_vals):.1f}%")

if __name__ == "__main__":
    main()
