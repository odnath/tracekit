# TraceKit colors. Sourced by tracekit.sh. Needs $BASE.
THEME_FILE="$BASE/.theme"

c() { printf '\033[%sm' "$1"; }                 # c "1;38;5;196"
fg() { printf '\033[1;38;5;%sm' "$1"; }         # 256-color bold
NC=$'\033[0m'

load_theme() {
  local t=ice; [ -f "$THEME_FILE" ] && t=$(cat "$THEME_FILE")
  case "$t" in
    fire)   LOGO=(196 202 208 214 220 226); ACC=208 ;;
    purple) LOGO=(93 99 105 111 117 123);   ACC=141 ;;
    green)  LOGO=(22 28 34 40 46 82);       ACC=46  ;;
    red)    LOGO=(52 88 124 160 196 203);   ACC=196 ;;
    *)      LOGO=(27 33 39 45 51 87);       ACC=51  ;;   # ice
  esac
}

choose_theme() {
  echo "Themes: ice, fire, purple, green, red"
  read -rp "Theme: " t
  case "$t" in ice|fire|purple|green|red) echo "$t" > "$THEME_FILE"; echo "Theme set to $t" ;;
    *) echo "Unknown theme." ;; esac
  sleep 1
}

print_menu() {
  local -a num=(1 2 3 4 5 6 7 8 9 t 0)
  local -a name=("Phone" "Email" "Username" "Domain" "File" "Instagram" "FULL footprint" "SpiderFoot / recon" "Check tools" "Change theme" "Exit")
  local -a info=("phonenumbers, PhoneInfoga, Ignorant, Veriphone"
                 "Holehe, EmailRep, GHunt, Mosint"
                 "Sherlock, Maigret, Blackbird, Social-Analyzer, Nexfil, +more"
                 "theHarvester, whois, dig, crt.sh"
                 "ExifTool, mat2, binwalk"
                 "Instaloader, Sherlock, Maigret"
                 "phone + email + username together"
                 "web UI, CLI scan, recon-ng, Maltego"
                 "which tools are installed"
                 "ice / fire / purple / green / red"
                 "")
  local -a col=(46 51 213 226 208 141 201 196 250 245 240)
  local i
  for i in "${!num[@]}"; do
    printf '  %s[%s]%s %s%-18s%s %s%s%s\n' \
      "$(fg ${col[i]})" "${num[i]}" "$NC" \
      "$(fg ${col[i]})" "${name[i]}" "$NC" \
      $'\033[38;5;244m' "${info[i]}" "$NC"
  done
  echo
}
