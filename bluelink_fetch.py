#!/usr/bin/env python3
"""
Hyundai Bluelink AU data fetcher — backend for the Flutter app.
Usage:  python3 bluelink_fetch.py <username> <password> <pin>
Requires: pip install hyundai-kia-connect-api
"""

import sys
import json
import traceback
from datetime import datetime, timezone


def safe(val):
    """Recursively convert any value to a JSON-serialisable primitive.
    Critically: bools MUST be checked before int (bool is subclass of int in Python).
    datetime objects are converted to local time before stringifying so that
    the daily stats are attributed to the correct local calendar date."""
    if val is None:
        return None
    if isinstance(val, bool):   # MUST come before int check
        return val              # preserves True/False exactly
    if isinstance(val, datetime):
        # Convert UTC-aware datetimes to local time so dates are correct
        # for the user's timezone (e.g. AEDT +11).
        if val.tzinfo is not None:
            val = val.astimezone()  # convert to local timezone
        return str(val)
    if isinstance(val, (int, float)):
        return val
    if isinstance(val, str):
        return val
    if isinstance(val, (list, tuple)):
        return [safe(i) for i in val]
    if isinstance(val, dict):
        return {k: safe(v) for k, v in val.items()}
    # Enum / custom object — str() gives the repr for datetime.datetime values
    # embedded inside other objects (e.g. DailyDrivingStats)
    s = str(val)
    try:
        return int(s)
    except (ValueError, TypeError):
        pass
    try:
        return float(s)
    except (ValueError, TypeError):
        pass
    return s


def vehicle_to_dict(v):
    """Dump ALL public non-callable attributes from a Vehicle object."""
    result = {}
    for attr in dir(v):
        if attr.startswith('_'):
            continue
        try:
            val = getattr(v, attr)
            if callable(val):
                continue
            result[attr] = safe(val)
        except Exception:
            pass
    return result


def main():
    if len(sys.argv) not in (4, 5):
        print(json.dumps({"error": "Usage: bluelink_fetch.py <username> <password> <pin>"}))
        sys.exit(1)

    username, password, pin = sys.argv[1], sys.argv[2], sys.argv[3]
    debug = len(sys.argv) == 5 and sys.argv[4] == '--debug'

    try:
        from hyundai_kia_connect_api import VehicleManager
    except ImportError:
        print(json.dumps({
            "error": "hyundai_kia_connect_api not installed",
            "fix": "Run: pip install hyundai-kia-connect-api"
        }))
        sys.exit(1)

    try:
        vm = VehicleManager(region=5, brand=2,
                            username=username, password=password, pin=pin)
        vm.check_and_refresh_token()
        vm.update_all_vehicles_with_cached_state()

        vehicles = []
        for vid, v in vm.vehicles.items():
            d = vehicle_to_dict(v)
            d['vehicleId'] = vid
            vehicles.append(d)

        if debug:
            # Pretty-print all fields for debugging
            for vd in vehicles:
                print(f"\n=== {vd.get('name', vd.get('vehicleId'))} ===")
                for k, val in sorted(vd.items()):
                    if val is not None and val != '' and val != []:
                        print(f"  {k}: {repr(val)}")
        else:
            print(json.dumps({"vehicles": vehicles}))

    except Exception as e:
        print(json.dumps({
            "error": str(e),
            "traceback": traceback.format_exc()
        }))
        sys.exit(1)


if __name__ == "__main__":
    main()
