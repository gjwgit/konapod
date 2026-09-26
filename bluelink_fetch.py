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

REGION = 5   # Australia
BRAND = 2    # Hyundai

# 20260926 gjw Hyundai's CCSP signin endpoint answers HTTP 200 with
# {"step": N} and NO redirectUrl when the account authenticated fine but must
# do something in the app or web portal before OAuth will hand over a code.
# KiaUvoApiAU.login() wraps that call in a bare `except Exception`, logs it at
# DEBUG without exc_info, and raises AuthenticationError("Login Failed") — so
# the step number is thrown away and the real reason never reaches us.
# These numbers are decoded in hyundai_kia_connect_api/HyundaiBlueLinkApiBR.py,
# which reads the same endpoint on the same platform for the Brazilian region.
SIGNIN_STEPS = {
    0: "the account must accept the terms of service",
    3: "the account must accept the data-access agreement",
    4: "the account must re-accept updated terms of service",
    # 20260926 gjw Step 5 is the one seen in the wild, and it is not obvious
    # from the app: Hyundai appears to expire a Bluelink password after about
    # six months, so a login that has worked for months starts failing with
    # nothing having changed at this end. Opening the Bluelink app on the
    # phone prompts for a new password; setting one there and updating it in
    # Settings restores the connection.
    5: "the password has expired and must be reset",
    6: "the account is not activated yet",
    7: "identity verification is required",
    8: "identity verification is required",
    9: "the account is blocked",
    10: "email verification is required",
    11: "the account email must be changed",
    12: "identity verification is required",
    13: "email verification is required",
}


def diagnose_login(username, password):
    """Ask the signin endpoint directly why it refused, after a failed login.

    Repeats the two calls KiaUvoApiAU.login() makes before it gives up, and
    reads the step code out of the response it discarded. Only ever runs on
    the failure path, so the happy path still signs in exactly once.

    Returns (step, reason); either may be None if the cause is something else.
    """
    try:
        import requests
        from hyundai_kia_connect_api.KiaUvoApiAU import KiaUvoApiAU

        api = KiaUvoApiAU(region=REGION, brand=BRAND, language="en")
        authorize = (
            api.USER_API_URL + "oauth2/authorize?response_type=code&client_id="
            + api.CLIENT_ID + "&redirect_uri=https://" + api.BASE_URL
            + "/api/v1/user/oauth2/redirect&lang=en"
        )
        session = requests.Session()
        session.get(authorize, timeout=20)
        body = session.post(
            api.USER_API_URL + "signin",
            json={"email": username, "password": password},
            headers={"Content-type": "application/json"},
            cookies=session.cookies.get_dict(),
            timeout=20,
        ).json()
    except Exception:
        # Network, JSON or import trouble — the original error stands.
        return None, None

    if "redirectUrl" in body:
        # Signin works on its own, so the failure was later in the OAuth
        # exchange and the original traceback is the better evidence.
        return None, None

    step = body.get("step")
    return step, SIGNIN_STEPS.get(step)


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
        vm = VehicleManager(region=REGION, brand=BRAND,
                            username=username, password=password, pin=pin)
        vm.check_and_refresh_token()
        vm.update_all_vehicles_with_cached_state()

        vehicles = []
        for vid, v in vm.vehicles.items():
            d = vehicle_to_dict(v)
            d['vehicleId'] = vid
            # 20260803 gjw last_updated_at comes back naive but is UTC; stamp it
            # so the Dart side parses the correct local time.
            lu = getattr(v, 'last_updated_at', None)
            if isinstance(lu, datetime) and lu.tzinfo is None:
                d['last_updated_at'] = str(lu.replace(tzinfo=timezone.utc).astimezone())
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
        out = {
            "error": str(e),
            "traceback": traceback.format_exc()
        }

        # "Login Failed" is the library's placeholder, not a diagnosis. Go
        # back and ask the server what it actually objected to.
        if type(e).__name__ == "AuthenticationError":
            step, reason = diagnose_login(username, password)
            if reason is not None:
                out["error"] = f"Login refused: {reason}."
                out["signinStep"] = step
                out["fix"] = ("Sign in to the Bluelink app or the MyHyundai "
                              "portal, complete that step, then retry.")
            elif step is not None:
                out["error"] = (f"Login refused at signin step {step}, which "
                                "is not a step this script knows about.")
                out["signinStep"] = step

        print(json.dumps(out))
        sys.exit(1)


if __name__ == "__main__":
    main()
