# TraceKit startup animation, sourced by osint.sh (or tracekit.sh)

typewrite() {  # usage: typewrite "text" [delay]
  local s="$1" d="${2:-0.02}" i
  for ((i=0; i<${#s}; i++)); do
    printf '%s' "${s:$i:1}"; sleep "$d"
  done
  echo
}

glitch_line() {  # prints a line with brief random-noise flicker, then the real line
  local line="$1" noise="▓▒░█▄▀■□◆#@%&" out="" i n=${#1}
  for pass in 1 2; do
    out=""
    for ((i=0; i<n; i++)); do
      if (( RANDOM % 4 == 0 )) && [ "${line:$i:1}" != " " ]; then
        out+="${noise:RANDOM%${#noise}:1}"
      else
        out+="${line:$i:1}"
      fi
    done
    printf '\r\033[0;32m%s\033[0m' "$out"; sleep 0.04
  done
  printf '\r\033[1;36m%s\033[0m\n' "$line"
}

progress_bar() {  # usage: progress_bar "label"
  local label="$1" w=40 i
  for ((i=0; i<=w; i++)); do
    printf '\r\033[0;32m%-18s\033[0m[\033[1;36m%s\033[0m%s] %3d%%' \
      "$label" "$(printf '█%.0s' $(seq 1 $i))" "$(printf '·%.0s' $(seq 1 $((w-i))))" $((i*100/w))
    sleep 0.02
  done
  echo
}

intro_animation() {
  [ -t 1 ] || return 0           # skip if output is not a terminal
  clear
  tput civis 2>/dev/null          # hide cursor
  trap 'tput cnorm 2>/dev/null' RETURN

  printf '\033[0;32m'
  typewrite "> initializing TraceKit core..." 0.025
  typewrite "> loading modules: phone | email | username | domain | file" 0.012
  typewrite "> consent check: OWN DATA OR WRITTEN CONSENT ONLY" 0.012
  printf '\033[0m'
  progress_bar "Loading tools"
  sleep 0.3
  clear

  glitch_line " ████████╗██████╗  █████╗  ██████╗███████╗██╗  ██╗██╗████████╗"
  glitch_line " ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║ ██╔╝██║╚══██╔══╝"
  glitch_line "    ██║   ██████╔╝███████║██║     █████╗  █████╔╝ ██║   ██║   "
  glitch_line "    ██║   ██╔══██╗██╔══██║██║     ██╔══╝  ██╔═██╗ ██║   ██║   "
  glitch_line "    ██║   ██║  ██║██║  ██║╚██████╗███████╗██║  ██╗██║   ██║   "
  glitch_line "    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝   "
  echo
  printf '\033[1;33m        '
  typewrite "Educational OSINT Toolkit  |  Own data or consent only" 0.02
  printf '\033[0m'
  sleep 0.8
}
