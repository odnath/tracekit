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
    echo "[PhoneInfoga]"; phoneinfoga scan -n "$N" 2>&1 | tee "$OUT/phone_phoneinfoga.txt"
  fi
  if has ignorant; then
    echo "[Ignorant]"; ignorant --no-clear --no-color "+$CC" "$NATIONAL" 2>&1 | tee "$OUT/phone_ignorant.txt"
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
    echo "[Holehe]"; holehe --no-color --no-clear --only-used "$E" 2>&1 | tee "$OUT/email_holehe.txt"
  fi
  echo "[EmailRep]"; curl -s "https://emailrep.io/$E" 2>&1 | tee "$OUT/email_emailrep.txt"; echo
  if has ghunt; then
    echo "[GHunt]"; ghunt email "$E" 2>&1 | tee "$OUT/email_ghunt.txt"
  fi
  if has mosint; then
    echo "[Mosint]"; mosint "$E" 2>&1 | tee "$OUT/email_mosint.txt"
  fi
  email_extra "$E" "$OUT"
  echo "Manual: https://haveibeenpwned.com (own email only)" > "$OUT/email_manual.txt"
}

user_scan() {
  local U="$1" OUT="$2"
  if has sherlock; then
    echo "[Sherlock]"; sherlock "$U" --print-found --timeout 10 --output "$OUT/user_sherlock.txt" 2>&1 | tee "$OUT/user_sherlock_log.txt"
  fi
  if has maigret; then
    echo "[Maigret]"; maigret "$U" --no-progressbar --no-color -T --folderoutput "$OUT/maigret" 2>&1 | tee "$OUT/user_maigret.txt"
  fi
  if [ -f "$BASE/tools/blackbird/venv/bin/python" ]; then
    echo "[Blackbird]"; (cd "$BASE/tools/blackbird" && venv/bin/python blackbird.py -u "$U") 2>&1 | tee "$OUT/user_blackbird.txt"
  fi
  if has social-analyzer; then
    echo "[Social-Analyzer]"; social-analyzer --username "$U" --top 50 --output json 2>&1 | tee "$OUT/user_social_analyzer.txt"
  fi
  if has nexfil; then
    echo "[Nexfil]"; nexfil -u "$U" 2>&1 | tee "$OUT/user_nexfil.txt"
  fi
  if has socialscan; then
    echo "[Socialscan]"; socialscan "$U" 2>&1 | tee "$OUT/user_socialscan.txt"
  fi
  if has user-scanner; then
    echo "[user-scanner]"; user-scanner -u "$U" 2>&1 | tee "$OUT/user_userscanner.txt"
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
  has theHarvester && { echo "[theHarvester]"; theHarvester -d "$D" -b crtsh,duckduckgo 2>&1 | tee "$OUT/domain_theharvester.txt"; }
  echo "[whois]"; whois "$D" 2>&1 | tee "$OUT/domain_whois.txt"
  echo "[dig]";   dig "$D" ANY +noall +answer 2>&1 | tee "$OUT/domain_dig.txt"
  domain_extra "$D" "$OUT"
  finish "$OUT"
}

do_file() {
  read -rp "Path to your photo/document: " F
  [ -f "$F" ] || { echo "File not found."; return; }
  consent || return
  OUT="$BASE/output/file_$(basename "$F")_$STAMP"; mkdir -p "$OUT"
  echo "[ExifTool]"; exiftool "$F" 2>&1 | tee "$OUT/file_exiftool.txt"
  file_extra "$F" "$OUT"
  finish "$OUT"
}

do_instagram() {
  read -rp "Your Instagram username: " U
  consent || return
  OUT="$BASE/output/insta_${U}_$STAMP"; mkdir -p "$OUT"
  IPY="$HOME/.local/share/pipx/venvs/instaloader/bin/python"
  echo "[Instaloader]"; "$IPY" "$BASE/insta_profile.py" "$U" 2>&1 | tee "$OUT/insta_instaloader.txt"
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

source "$BASE/extras.sh"

while true; do
  echo
  echo "===== OSINT LAB MENU ====="
  echo "1) Phone      (phonenumbers, PhoneInfoga, Ignorant, Veriphone)"
  echo "2) Email      (Holehe, EmailRep, GHunt, Mosint)"
  echo "3) Username   (Sherlock, Maigret, Blackbird, Social-Analyzer, Nexfil, Socialscan, user-scanner)"
  echo "4) Domain     (theHarvester, whois, dig)"
  echo "5) File       (ExifTool)"
  echo "6) Instagram  (Instaloader)"
  echo "7) FULL footprint (phone + email + username together)"
  echo "8) SpiderFoot web UI"
  echo "9) Check installed tools"
  echo "0) Exit"
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
