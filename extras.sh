# Extra tools, sourced by osint.sh. Uses has(), consent(), finish(), BASE, PY, STAMP.

phone_extra() {
  local N="$1" OUT="$2" Q
  echo "[phonenumbers extended]"
  "$PY" - <<EOT 2>&1 | tee "$OUT/phone_extended.txt"
import phonenumbers as p
from phonenumbers import PhoneNumberType as T
n = p.parse("$N")
names = {v: k for k, v in vars(T).items() if isinstance(v, int)}
print("Possible number:", p.is_possible_number(n))
print("Line type:", names.get(p.number_type(n)))
print("E164:", p.format_number(n, p.PhoneNumberFormat.E164))
print("National:", p.format_number(n, p.PhoneNumberFormat.NATIONAL))
print("RFC3966:", p.format_number(n, p.PhoneNumberFormat.RFC3966))
EOT
  Q=$("$PY" -c "import urllib.parse,sys;print(urllib.parse.quote('\"'+sys.argv[1]+'\"'))" "$N")
  {
    echo "Search links (open manually, own number only):"
    echo "https://duckduckgo.com/?q=$Q"
    echo "https://www.bing.com/search?q=$Q"
    echo "https://yandex.com/search/?text=$Q"
  } > "$OUT/phone_searchlinks.txt"
  cat "$OUT/phone_searchlinks.txt"
   if [ -n "$TWILIO_SID" ] && [ -n "$TWILIO_TOKEN" ]; then
    echo "[Twilio Lookup]"
    curl -s -u "$TWILIO_SID:$TWILIO_TOKEN" \
      "https://lookups.twilio.com/v2/PhoneNumbers/$(printf %s "$N" | sed 's/+/%2B/')?Fields=line_type_intelligence" \
      | tee "$OUT/phone_twilio.txt"; echo
  fi
}

email_extra() {
  local E="$1" OUT="$2" H DOM
  DOM="${E#*@}"
  echo "[MX records]"; dig MX "$DOM" +short 2>&1 | tee "$OUT/email_mx.txt"
  echo "[Gravatar]"
  H=$(printf '%s' "${E,,}" | md5sum | cut -d' ' -f1)
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://www.gravatar.com/avatar/$H?d=404")
  if [ "$CODE" = "200" ]; then
    echo "Gravatar profile EXISTS: https://gravatar.com/$H" | tee "$OUT/email_gravatar.txt"
  else
    echo "No Gravatar found (HTTP $CODE)" | tee "$OUT/email_gravatar.txt"
  fi
  if has h8mail; then
    echo "[h8mail - own email only]"; h8mail -t "$E" 2>&1 | tee "$OUT/email_h8mail.txt"
  fi
}

domain_extra() {
  local D="$1" OUT="$2"
  echo "[crt.sh subdomains]"
  curl -s "https://crt.sh/?q=%25.$D&output=json" | "$PY" -c "import sys,json
try:
  d=json.load(sys.stdin)
  print('\n'.join(sorted({n for r in d for n in r['name_value'].split('\n')})))
except Exception as e:
  print('crt.sh unavailable:', e)" | tee "$OUT/domain_crtsh.txt"
  echo "[Wayback Machine URLs]"
  curl -s "https://web.archive.org/cdx/search/cdx?url=$D/*&output=text&fl=original&collapse=urlkey&limit=100" | tee "$OUT/domain_wayback.txt"
  has whatweb   && { echo "[whatweb]";   whatweb "$D" 2>&1 | tee "$OUT/domain_whatweb.txt"; }
  has wafw00f   && { echo "[wafw00f]";   wafw00f "https://$D" 2>&1 | tee "$OUT/domain_wafw00f.txt"; }
  has sslscan   && { echo "[sslscan]";   sslscan "$D" 2>&1 | tee "$OUT/domain_sslscan.txt"; }
  has dnsrecon  && { echo "[dnsrecon]";  dnsrecon -d "$D" 2>&1 | tee "$OUT/domain_dnsrecon.txt"; }
  has subfinder && { echo "[subfinder]"; subfinder -d "$D" -silent 2>&1 | tee "$OUT/domain_subfinder.txt"; }
  has amass     && { echo "[amass passive, max 5 min]"; timeout 300 amass enum -passive -d "$D" 2>&1 | tee "$OUT/domain_amass.txt"; }
}

file_extra() {
  local F="$1" OUT="$2"
  echo "[file]"; file "$F" 2>&1 | tee "$OUT/file_type.txt"
  echo "[strings (first 60)]"; strings -n 8 "$F" 2>&1 | head -60 | tee "$OUT/file_strings.txt"
  has binwalk && { echo "[binwalk]"; binwalk "$F" 2>&1 | tee "$OUT/file_binwalk.txt"; }
  has mat2    && { echo "[mat2 metadata]"; mat2 --show "$F" 2>&1 | tee "$OUT/file_mat2.txt"; }
  case "${F,,}" in *.pdf) has pdfinfo && { echo "[pdfinfo]"; pdfinfo "$F" 2>&1 | tee "$OUT/file_pdfinfo.txt"; } ;; esac
  echo "Tip: 'mat2 yourfile' creates a cleaned copy with metadata removed." | tee -a "$OUT/file_mat2.txt"
}

insta_extra() {
  local U="$1" OUT="$2"
  has sherlock && { echo "[Sherlock - Instagram only]"; sherlock "$U" --site Instagram --print-found --timeout 10 2>&1 | tee "$OUT/insta_sherlock.txt"; }
  has maigret  && { echo "[Maigret - Instagram only]"; maigret "$U" --site Instagram --no-progressbar --no-color 2>&1 | tee "$OUT/insta_maigret.txt"; }
  cat > "$OUT/insta_manual.txt" <<EOT
Manual checks (own account):
1. Open https://www.instagram.com/$U/ in a logged-out/private window and note what a stranger sees.
2. Settings > Accounts Center: which email/phone are linked to the account?
3. Settings > Privacy: who can find you by phone number or email?
4. Reverse image search your profile photo:
   https://lens.google.com
   https://tineye.com
   https://yandex.com/images
5. Download a photo you posted and run menu 5 (File) to check for GPS metadata.
EOT
  cat "$OUT/insta_manual.txt"
}

do_spiderfoot() {
  local SF="$BASE/tools/spiderfoot" m T OUT
  echo "a) SpiderFoot web UI"
  echo "b) SpiderFoot CLI passive scan (saved to output)"
  echo "c) recon-ng"
  echo "d) Maltego"
  read -rp "Choose: " m
  case "$m" in
    a|b) [ -f "$SF/venv/bin/python" ] || { echo "SpiderFoot is not installed."; return; } ;;
  esac
  case "$m" in
    a) (cd "$SF" && venv/bin/python sf.py -l 127.0.0.1:5001) ;;
    b) read -rp "Target (domain, email, IP or phone): " T
       consent || return
       OUT="$BASE/output/spiderfoot_${T//[^A-Za-z0-9]/_}_$STAMP"; mkdir -p "$OUT"
       (cd "$SF" && venv/bin/python sf.py -s "$T" -u passive -q -o csv) 2>&1 | tee "$OUT/spiderfoot.txt"
       finish "$OUT" ;;
    c) has recon-ng && recon-ng || echo "recon-ng is not installed." ;;
    d) has maltego && maltego >/dev/null 2>&1 & ;;
    *) echo "Invalid choice." ;;
  esac
}
