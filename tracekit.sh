#!/bin/bash
BASE="$(cd "$(dirname "$0")" && pwd)"
PY="$BASE/venv/bin/python"
STAMP="$(date +%F_%H%M)"
[ -f "$BASE/.env" ] && { set -a; . "$BASE/.env"; set +a; }

has() { command -v "$1" >/dev/null 2>&1; }

consent() {
  read -rp "Is this YOUR data or do you have written consent? (yes/no): " a
  [ "$a" = "yes" ] || { echo "Cancelled."; return 1; }
}

finish() {
  "$PY" "$BASE/make_generic_report.py" "$1"
  xdg-open "$1/report.html" >/dev/null 2>&1 &
  echo "Saved in: $1"
}

# ---------- scan functions (each takes target + output folder) ----------

phone_scan() {
  local N="$1" OUT="$2" CC NATIONAL
  read CC NATIONAL < <("$PY" -c "
import phonenumbers as p
n = p.parse('$N'); print(n.country_code, n.national_number)")
  echo "[phonenumbers]"
  "$PY" - <<EOT 2>&1 | tee "$OUT/phone_phonenumbers.txt"
import phonenumbers as p
from phonenumbers import geocoder, carrier, timezone
n = p.parse("$N")
print("Valid:", p.is_valid_number(n))
print("Region:", geocoder.description_for_number(n, "en"))
print("Carrier:", carrier.name_for_number(n, "en"))
print("Timezone:", timezone.time_zones_for_number(n))
print("International:", p.format_number(n, p.PhoneNumberFormat.INTERNATIONAL))
EOT
  if has phoneinfoga; then
    run_tool "PhoneInfoga" "$OUT/phone_phoneinfoga.txt" phoneinfoga scan -n "$N"
  fi
  if has ignorant; then
    run_tool "Ignorant" "$OUT/phone_ignorant.txt" ignorant --no-clear --no-color "+$CC" "$NATIONAL"
  fi
  if [ -n "$VERIPHONE_KEY" ]; then
    echo "[Veriphone]"; curl -s "https://api.veriphone.io/v2/verify?phone=${N}&key=${VERIPHONE_KEY}" | tee "$OUT/phone_veriphone.txt"; echo
  fi
  phone_extra "$N" "$OUT"
  printf "Manual checks (own number only):\nhttps://epieos.com\nhttps://www.truecaller.com\nhttps://sync.me\nWhatsApp/Telegram: ask a friend what they can see of your profile\n" > "$OUT/phone_manual.txt"
}

email_scan() {
  local E="$1" OUT="$2"
  if has holehe; then
    run_tool "Holehe" "$OUT/email_holehe.txt" holehe --no-color --no-clear --only-used "$E"
  fi
  run_tool "EmailRep" "$OUT/email_emailrep.txt" curl -s "https://emailrep.io/$E"; echo
  if has ghunt; then
    run_tool "GHunt" "$OUT/email_ghunt.txt" ghunt email "$E"
  fi
  if has mosint; then
    run_tool "Mosint" "$OUT/email_mosint.txt" mosint "$E"
  fi
  email_extra "$E" "$OUT"
  echo "Manual: https://haveibeenpwned.com (own email only)" > "$OUT/email_manual.txt"
}

user_scan() {
  local U="$1" OUT="$2"
  if has sherlock; then
    run_tool "Sherlock" "$OUT/user_sherlock_log.txt" sherlock "$U" --print-found --timeout 10 --output "$OUT/user_sherlock.txt"
  fi
  if has maigret; then
    run_tool "Maigret" "$OUT/user_maigret.txt" maigret "$U" --no-progressbar --no-color -T --folderoutput "$OUT/maigret"
  fi
  if [ -f "$BASE/tools/blackbird/venv/bin/python" ]; then
    run_tool "Blackbird" "$OUT/user_blackbird.txt" (cd "$BASE/tools/blackbird" && venv/bin/python blackbird.py -u "$U")
  fi
  if has social-analyzer; then
    run_tool "Social-Analyzer" "$OUT/user_social_analyzer.txt" social-analyzer --username "$U" --top 50 --output json
  fi
  if has nexfil; then
    run_tool "Nexfil" "$OUT/user_nexfil.txt" nexfil -u "$U"
  fi
  if has socialscan; then
    run_tool "Socialscan" "$OUT/user_socialscan.txt" socialscan "$U"
  fi
  if has user-scanner; then
    run_tool "user-scanner" "$OUT/user_userscanner.txt" user-scanner -u "$U"
  fi
  printf "Manual:\nhttps://whatsmyname.app\nhttps://namechk.com\n" > "$OUT/user_manual.txt"
}

# ---------- menu actions ----------

do_phone() {
  read -rp "Phone number (+91...): " N
  consent || return
  OUT="$BASE/output/phone_${N//+/}_$STAMP"; mkdir -p "$OUT"
  phone_scan "$N" "$OUT"; finish "$OUT"
}

do_email() {
  read -rp "Email address: " E
  consent || return
  OUT="$BASE/output/email_${E//[@.]/_}_$STAMP"; mkdir -p "$OUT"
  email_scan "$E" "$OUT"; finish "$OUT"
}

do_username() {
  read -rp "Username: " U
  consent || return
  OUT="$BASE/output/user_${U}_$STAMP"; mkdir -p "$OUT"
  user_scan "$U" "$OUT"; finish "$OUT"
}

do_domain() {
  read -rp "Domain you own (example.com): " D
  consent || return
  OUT="$BASE/output/domain_${D}_$STAMP"; mkdir -p "$OUT"
  has theHarvester && { run_tool "theHarvester" "$OUT/domain_theharvester.txt" theHarvester -d "$D" -b crtsh,duckduckgo; }
  run_tool "whois" "$OUT/domain_whois.txt" whois "$D"
  run_tool "dig" "$OUT/domain_dig.txt" dig "$D" ANY +noall +answer
  domain_extra "$D" "$OUT"
  finish "$OUT"
}

do_file() {
  read -rp "Path to your photo/document: " F
  [ -f "$F" ] || { echo "File not found."; return; }
  consent || return
  OUT="$BASE/output/file_$(basename "$F")_$STAMP"; mkdir -p "$OUT"
  run_tool "ExifTool" "$OUT/file_exiftool.txt" exiftool "$F"
  file_extra "$F" "$OUT"
  finish "$OUT"
}

do_instagram() {
  read -rp "Your Instagram username: " U
  consent || return
  OUT="$BASE/output/insta_${U}_$STAMP"; mkdir -p "$OUT"
  IPY="$HOME/.local/share/pipx/venvs/instaloader/bin/python"
  run_tool "Instaloader" "$OUT/insta_instaloader.txt" "$IPY" "$BASE/insta_profile.py" "$U"
  insta_extra "$U" "$OUT"
  finish "$OUT"
}

do_full() {
  echo "Leave any field empty to skip it."
  read -rp "Phone (+91...): " N
  read -rp "Email: " E
  read -rp "Username: " U
  consent || return
  OUT="$BASE/output/full_$STAMP"; mkdir -p "$OUT"
  [ -n "$N" ] && { echo "=== PHONE ==="; phone_scan "$N" "$OUT"; }
  [ -n "$E" ] && { echo "=== EMAIL ==="; email_scan "$E" "$OUT"; }
  [ -n "$U" ] && { echo "=== USERNAME ==="; user_scan "$U" "$OUT"; }
  finish "$OUT"
}

do_check() {
  for t in phoneinfoga ignorant holehe ghunt mosint maigret sherlock social-analyzer nexfil socialscan user-scanner theHarvester exiftool whois dig; do
    has "$t" && echo "OK       $t" || echo "MISSING  $t"
  done
  [ -f "$PY" ] && echo "OK       phonenumbers venv" || echo "MISSING  phonenumbers venv"
  [ -f "$BASE/tools/blackbird/venv/bin/python" ] && echo "OK       blackbird" || echo "MISSING  blackbird"
  [ -n "$VERIPHONE_KEY" ] && echo "OK       Veriphone key" || echo "MISSING  Veriphone key (optional)"
}

source "$BASE/runner.sh"
source "$BASE/extras.sh"
source "$BASE/banner.sh"
source "$BASE/animation.sh"
intro_animation

while true; do
  banner
  echo -e "\033[1;33m1)\033[0m Phone      (phonenumbers, PhoneInfoga, Ignorant, Veriphone)"
  echo -e "\033[1;33m2)\033[0m Email      (Holehe, EmailRep, GHunt, Mosint)"
  echo -e "\033[1;33m3)\033[0m Username   (Sherlock, Maigret, Blackbird, Social-Analyzer, Nexfil, Socialscan, user-scanner)"
  echo -e "\033[1;33m4)\033[0m Domain     (theHarvester, whois, dig)"
  echo -e "\033[1;33m5)\033[0m File       (ExifTool)"
  echo -e "\033[1;33m6)\033[0m Instagram  (Instaloader)"
  echo -e "\033[1;33m7)\033[0m FULL footprint (phone + email + username together)"
  echo -e "\033[1;33m8)\033[0m SpiderFoot web UI"
  echo -e "\033[1;33m9)\033[0m Check installed tools"
  echo -e "\033[1;33m0)\033[0m Exit"
  read -rp "Choose: " c
  case "$c" in
    1) do_phone ;;
    2) do_email ;;
    3) do_username ;;
    4) do_domain ;;
    5) do_file ;;
    6) do_instagram ;;
    7) do_full ;;
    8) do_spiderfoot ;;
    9) do_check ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
