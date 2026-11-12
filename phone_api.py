#!/usr/bin/env python3
"""Usage: phone_api.py +919876543210  (needs NUMVERIFY_KEY in .env)"""
import sys, json, os, pathlib, urllib.request, urllib.parse

env = pathlib.Path(__file__).parent / ".env"
if env.exists():
    for line in env.read_text().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())

key = os.environ.get("NUMVERIFY_KEY")
if not key or key == "paste_your_key_here":
    sys.exit("Error: put your real NUMVERIFY_KEY in .env")

num = sys.argv[1].lstrip("+")
url = "https://api.apilayer.com/number_verification/validate?number=" + num
req = urllib.request.Request(url, headers={"apikey": key})
try:
    data = json.load(urllib.request.urlopen(req, timeout=20))
    for k, v in data.items():
        print(f"{k}: {v}")
except Exception as e:
    print("Error:", e)
