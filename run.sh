#!/bin/bash
# Usage: ./run.sh +919876543210
NUM="$1"
[ -z "$NUM" ] && { echo "Usage: $0 +<countrycode><number>"; exit 1; }

BASE="$(cd "$(dirname "$0")" && pwd)"
PY="$BASE/venv/bin/python"
OUT="$BASE/output/${NUM//+/}_$(date +%F_%H%M)"
mkdir -p "$OUT"

read CC NATIONAL < <($PY -c "
import phonenumbers as p
n = p.parse('$NUM')
print(n.country_code, n.national_number)
")

echo "[1] Basic info (phonenumbers)"
$PY - <<EOF | tee "$OUT/phonenumbers.txt"
import phonenumbers as p
from phonenumbers import geocoder, carrier, timezone
n = p.parse("$NUM")
print("Valid:", p.is_valid_number(n))
print("Region:", geocoder.description_for_number(n, "en"))
print("Carrier:", carrier.name_for_number(n, "en"))
print("Timezone:", timezone.time_zones_for_number(n))
print("International:", p.format_number(n, p.PhoneNumberFormat.INTERNATIONAL))
EOF

echo; echo "[2] PhoneInfoga"
phoneinfoga scan -n "$NUM" | tee "$OUT/phoneinfoga.txt"

echo; echo "[3] Ignorant"
ignorant --no-clear --no-color "+$CC" "$NATIONAL" 2>&1 | tee "$OUT/ignorant.txt"

echo; echo "[4] Google dorks (search these manually)"
cat > "$OUT/dorks.txt" <<EOF
"$NUM"
"$NATIONAL"
"$CC$NATIONAL"
intext:"$NATIONAL" site:facebook.com
intext:"$NATIONAL" filetype:pdf
EOF
cat "$OUT/dorks.txt"

echo; echo "Done. Results saved in $OUT"
