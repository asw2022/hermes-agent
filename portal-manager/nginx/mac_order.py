#!/usr/bin/env python3
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

"""Helper to sort MAC addresses by their success rate.

Reads a list of valid MACs from stdin, loads stats from the supplied stats file,
applies the configured thresholds, and emits three tagged sections:
- Q lines for MACs that already meet the attempt+success thresholds
- R lines for the remaining MACs (still in their computed rate order)
- B lines for all MACs sorted by success rate (used when no Q entries exist)
"""

import sys
from pathlib import Path

def parse_stats(stats_path: Path) -> dict[str, tuple[int, int]]:
    result: dict[str, tuple[int, int]] = {}
    if not stats_path.exists():
        return result
    try:
        with stats_path.open() as stats_file:
            for line in stats_file:
                parts = line.strip().split("|")
                if len(parts) < 3:
                    continue
                mac = parts[0].strip()
                if not mac:
                    continue
                succ = int(parts[1]) if parts[1].isdigit() else 0
                att = int(parts[2]) if parts[2].isdigit() else 0
                result[mac] = (succ, att)
    except (OSError, ValueError):
        return result
    return result

def compute_rate(success: int, attempts: int) -> float:
    if attempts <= 0:
        return 0.0
    return success / attempts

def main() -> int:
    if len(sys.argv) != 4:
        print("Error: Expected stats_path, min_attempts, min_success_rate", file=sys.stderr)
        return 1

    stats_path = Path(sys.argv[1])
    try:
        min_attempts = int(sys.argv[2])
        min_success_rate = float(sys.argv[3])
    except ValueError:
        print("Error: Invalid threshold values", file=sys.stderr)
        return 1

    stats = parse_stats(stats_path)
    valid_macs = [line.strip() for line in sys.stdin if line.strip()]
    if not valid_macs:
        return 0

    qualified: list[tuple[float, str]] = []
    fallback: list[tuple[float, str]] = []
    best_effort: list[tuple[float, str]] = []

    for mac in valid_macs:
        succ, att = stats.get(mac, (0, 0))
        rate = compute_rate(succ, att)
        best_effort.append((rate, mac))
        if att >= min_attempts and rate >= min_success_rate:
            qualified.append((rate, mac))
        else:
            fallback.append((rate, mac))

    qualified.sort(key=lambda item: (item[0], item[1]), reverse=True)
    fallback.sort(key=lambda item: (item[0], item[1]), reverse=True)
    best_effort.sort(key=lambda item: (item[0], item[1]), reverse=True)

    for rate, mac in qualified:
        print(f"Q|{rate:.8f}|{mac}")
    for rate, mac in fallback:
        print(f"R|{rate:.8f}|{mac}")
    for rate, mac in best_effort:
        print(f"B|{rate:.8f}|{mac}")

    return 0

if __name__ == "__main__":
    raise SystemExit(main())
