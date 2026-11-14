#!/bin/bash
# TraceKit main script. One menu, printed once, from print_menu in theme.sh.
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
  read -rp "Press Enter to return to the menu..." _
}

for f in runner theme banner extras animation2; do
  [ -f "$BASE/$f.sh" ] && source "$BASE/$f.sh"
done

# ---------- scans ----------
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
  has phoneinfoga && run_tool "PhoneInfoga" "$OUT/phone_phoneinfoga.txt" phoneinfoga scan -n "$N"
  has ignorant && run_tool "Ignorant" "$OUT/phone_ignorant.txt" ignorant --no-clear --no-color "+$CC" "$NATIONAL"
  if [ -n "$VERIPHONE_KEY" ]; then
    run_tool "Veriphone" "$OUT/phone_veriphone.txt" curl -s "https://api.veriphone.io/v2/verify?phone=${N}&key=${VERIPHONE_KEY}"
  fi
  declare -F phone_extra >/dev/null && phone_extra "$N" "$OUT"
  printf "Manual checks (own number only):\nhttps://epieos.com\nhttps://www.truecaller.com\nhttps://sync.me\nWhatsApp/Telegram: ask a friend what they can see of your profile\n" > "$OUT/phone_manual.txt"
}

email_scan() {
  local E="$1" OUT="$2"
  has holehe && run_tool "Holehe" "$OUT/email_holehe.txt" holehe --no-color --no-clear --only-used "$E"
  run_tool "EmailRep" "$OUT/email_emailrep.txt" curl -s "https://emailrep.io/$E"
  has ghunt && run_tool "GHunt" "$OUT/email_ghunt.txt" ghunt email "$E"
  has mosint && run_tool "Mosint" "$OUT/email_mosint.txt" mosint "$E"
  declare -F email_extra >/dev/null && email_extra "$E" "$OUT"
  echo "Manual: https://haveibeenpwned.com (own email only)" > "$OUT/email_manual.txt"
}

user_scan() {
  local U="$1" OUT="$2"
  has sherlock && run_tool "Sherlock" "$OUT/user_sherlock_log.txt" sherlock "$U" --print-found --timeout 10 --output "$OUT/user_sherlock.txt"
  has maigret && run_tool "Maigret" "$OUT/user_maigret.txt" maigret "$U" --no-progressbar --no-color -T --folderoutput "$OUT/maigret"
  [ -f "$BASE/tools/blackbird/venv/bin/python" ] && run_tool "Blackbird" "$OUT/user_blackbird.txt" \
    bash -c 'cd "$1/tools/blackbird" && venv/bin/python blackbird.py -u "$2"' _ "$BASE" "$U"
  has social-analyzer && run_tool "Social-Analyzer" "$OUT/user_social_analyzer.txt" social-analyzer --username "$U" --top 50 --output json
  has nexfil && run_tool "Nexfil" "$OUT/user_nexfil.txt" nexfil -u "$U"
  has socialscan && run_tool "Socialscan" "$OUT/user_socialscan.txt" socialscan "$U"
  has user-scanner && run_tool "user-scanner" "$OUT/user_userscanner.txt" user-scanner -u "$U"
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
  has theHarvester && run_tool "theHarvester" "$OUT/domain_theharvester.txt" theHarvester -d "$D" -b crtsh,duckduckgo
  run_tool "whois" "$OUT/domain_whois.txt" whois "$D"
  run_tool "dig" "$OUT/domain_dig.txt" dig "$D" ANY +noall +answer
  declare -F domain_extra >/dev/null && domain_extra "$D" "$OUT"
  finish "$OUT"
}

do_file() {
  read -rp "Path to your photo/document: " F
  [ -f "$F" ] || { echo "File not found."; sleep 1; return; }
  consent || return
  OUT="$BASE/output/file_$(basename "$F")_$STAMP"; mkdir -p "$OUT"
  run_tool "ExifTool" "$OUT/file_exiftool.txt" exiftool "$F"
  declare -F file_extra >/dev/null && file_extra "$F" "$OUT"
  finish "$OUT"
}

do_instagram() {
  read -rp "Your Instagram username: " U
  consent || return
  OUT="$BASE/output/insta_${U}_$STAMP"; mkdir -p "$OUT"
  IPY="$HOME/.local/share/pipx/venvs/instaloader/bin/python"
  [ -f "$IPY" ] && run_tool "Instaloader" "$OUT/insta_instaloader.txt" "$IPY" "$BASE/insta_profile.py" "$U"
  declare -F insta_extra >/dev/null && insta_extra "$U" "$OUT"
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
  local t
  for t in phoneinfoga ignorant holehe ghunt mosint maigret sherlock social-analyzer nexfil socialscan user-scanner theHarvester exiftool whois dig; do
    has "$t" && echo "OK       $t" || echo "MISSING  $t"
  done
  [ -f "$PY" ] && echo "OK       phonenumbers venv" || echo "MISSING  phonenumbers venv"
  [ -f "$BASE/tools/blackbird/venv/bin/python" ] && echo "OK       blackbird" || echo "MISSING  blackbird"
}

# ---------- start ----------
[ "$1" = "--fast" ] || { declare -F intro_animation >/dev/null && intro_animation; }

while true; do
  banner
  print_menu
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
    9) do_check; read -rp "Press Enter to continue..." _ ;;
    t|T) choose_theme ;;
    0) exit 0 ;;
    *) echo "Invalid choice."; sleep 1 ;;
  esac
done
