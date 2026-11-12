#!/bin/bash
BASE="$(cd "$(dirname "$0")" && pwd)"
PY="$BASE/venv/bin/python"
STAMP="$(date +%F_%H%M)"

consent() {
  read -rp "Is this YOUR data or do you have written consent? (yes/no): " a
  [ "$a" = "yes" ] || { echo "Cancelled."; return 1; }
}

finish() {
  "$PY" "$BASE/make_generic_report.py" "$1"
  xdg-open "$1/report.html" >/dev/null 2>&1 &
  echo "Saved in: $1"
}

do_phone() {
  read -rp "Phone number (+91...): " N
  consent || return
  "$BASE/run.sh" "$N"
}

do_email() {
  read -rp "Email address: " E
  consent || return
  OUT="$BASE/output/email_${E//[@.]/_}_$STAMP"; mkdir -p "$OUT"
  echo "[Holehe]"
  holehe --no-color --no-clear --only-used "$E" 2>&1 | tee "$OUT/holehe.txt"
  finish "$OUT"
}

do_username() {
  read -rp "Username: " U
  consent || return
  OUT="$BASE/output/user_${U}_$STAMP"; mkdir -p "$OUT"
  echo "[Sherlock]"
  sherlock "$U" --print-found --timeout 10 --output "$OUT/sherlock.txt" 2>&1 | tee "$OUT/sherlock_log.txt"
  echo "[Maigret]"
  maigret "$U" --no-progressbar --no-color -T --folderoutput "$OUT/maigret" 2>&1 | tee "$OUT/maigret_log.txt"
  finish "$OUT"
}

do_domain() {
  read -rp "Domain you own (example.com): " D
  consent || return
  OUT="$BASE/output/domain_${D}_$STAMP"; mkdir -p "$OUT"
  echo "[theHarvester]"
  theHarvester -d "$D" -b crtsh,duckduckgo 2>&1 | tee "$OUT/theharvester.txt"
  echo "[whois]"
  whois "$D" 2>&1 | tee "$OUT/whois.txt"
  echo "[dig]"
  dig "$D" ANY +noall +answer 2>&1 | tee "$OUT/dig.txt"
  finish "$OUT"
}

do_file() {
  read -rp "Path to your photo/document: " F
  [ -f "$F" ] || { echo "File not found."; return; }
  consent || return
  OUT="$BASE/output/file_$(basename "$F")_$STAMP"; mkdir -p "$OUT"
  echo "[ExifTool]"
  exiftool "$F" 2>&1 | tee "$OUT/exiftool.txt"
  finish "$OUT"
}

do_instagram() {
  read -rp "Your Instagram username: " U
  consent || return
  OUT="$BASE/output/insta_${U}_$STAMP"; mkdir -p "$OUT"
  IPY="$HOME/.local/share/pipx/venvs/instaloader/bin/python"
  echo "[Instaloader - public profile data]"
  "$IPY" "$BASE/insta_profile.py" "$U" 2>&1 | tee "$OUT/instaloader.txt"
  finish "$OUT"
}

while true; do
  echo
  echo "===== OSINT LAB MENU ====="
  echo "1) Phone number   (phonenumbers, PhoneInfoga, Ignorant)"
  echo "2) Email          (Holehe)"
  echo "3) Username       (Sherlock, Maigret)"
  echo "4) Domain         (theHarvester, whois, dig)"
  echo "5) File metadata  (ExifTool)"
  echo "6) Start SpiderFoot web UI"
  echo "7) Instagram profile (Instaloader)"
  echo "0) Exit"
  read -rp "Choose: " c
  case "$c" in
    1) do_phone ;;
    2) do_email ;;
    3) do_username ;;
    4) do_domain ;;
    5) do_file ;;
    6) (cd "$BASE/tools/spiderfoot" && venv/bin/python sf.py -l 127.0.0.1:5001) ;;
    7) do_instagram ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
