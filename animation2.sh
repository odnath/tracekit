# TraceKit hacker-style intro. Overrides intro_animation. Needs has() from tracekit.sh.

_G='\033[0;32m'; _BG='\033[1;32m'; _C='\033[1;36m'; _Y='\033[1;33m'; _R='\033[1;31m'; _N='\033[0m'

tk_type() {  # tk_type "text" [delay]
  local s="$1" d="${2:-0.015}" i
  for ((i=0; i<${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep "$d"; done
  echo
}

matrix_rain() {  # matrix_rain [seconds]
  local dur="${1:-3}" cols lines x y end
  local chars='01ABCDEF23456789@#$%&*+=<>'
  cols=$(tput cols); lines=$(tput lines)
  local -a drop
  for ((x=0; x<cols; x++)); do drop[x]=$((RANDOM % lines)); done
  printf '\033[2J'
  end=$((SECONDS + dur))
  while ((SECONDS < end)); do
    for ((x=0; x<cols; x+=2)); do
      y=${drop[x]}
      printf '\033[%d;%dH\033[1;37m%s' $((y+1)) $((x+1)) "${chars:RANDOM%${#chars}:1}"
      ((y>0)) && printf '\033[%d;%dH\033[0;32m%s' "$y" $((x+1)) "${chars:RANDOM%${#chars}:1}"
      printf '\033[%d;%dH ' $(( (y + lines - 10) % lines + 1 )) $((x+1))   # erase trail
      if (( RANDOM % 25 == 0 )); then drop[x]=0; else drop[x]=$(( (y+1) % lines )); fi
    done
    sleep 0.03
  done
  printf '\033[0m'
}

boot_log() {  # real tool status, shown as a boot sequence
  local t
  for t in phoneinfoga ignorant holehe ghunt mosint maigret sherlock social-analyzer \
           nexfil socialscan user-scanner theHarvester exiftool whois dig; do
    sleep 0.07
    if has "$t"; then printf "${_G}[  OK  ]${_N} module %-18s loaded\n" "$t"
    else printf "${_R}[ MISS ]${_N} module %-18s not found\n" "$t"; fi
  done
}

hex_stream() {  # hex_stream [lines]
  local n="${1:-16}" i j line
  for ((i=0; i<n; i++)); do
    line=$(printf '0x%06X  ' $(( (RANDOM*RANDOM) % 16777216 )))
    for ((j=0; j<8; j++)); do line+=$(printf '%02X ' $((RANDOM % 256))); done
    printf "${_G}%s${_N}\n" "$line"; sleep 0.04
  done
}

bar() {  # bar "label"
  local label="$1" w=36 i f e
  for ((i=0; i<=w; i++)); do
    f=$(printf '█%.0s' $(seq 1 $i)); e=$(printf '░%.0s' $(seq 1 $((w-i))))
    printf "\r${_G}%-20s${_N}[${_C}%s${_N}%s] %3d%%" "$label" "$f" "$e" $((i*100/w))
    sleep 0.025
  done
  echo
}

decrypt_line() {  # random noise settles into the real line
  local line="$1" noise='▓▒░█#@%&$01' out frame i n=${#1}
  for frame in 1 2 3 4 5 6 7; do
    out=""
    for ((i=0; i<n; i++)); do
      if [ "${line:$i:1}" = " " ]; then out+=" "
      elif (( RANDOM % 7 < frame )); then out+="${line:$i:1}"
      else out+="${noise:RANDOM%${#noise}:1}"; fi
    done
    printf "\r${_G}%s${_N}" "$out"; sleep 0.05
  done
  printf "\r${_C}%s${_N}\n" "$line"
}

intro_animation() {
  [ -t 1 ] || return 0
  tput civis 2>/dev/null
  trap 'tput cnorm 2>/dev/null' RETURN INT

  matrix_rain 3
  clear
  printf "${_BG}"
  tk_type "> TRACEKIT v1.0 :: secure session starting..." 0.02
  tk_type "> establishing local sandbox ............ done" 0.01
  tk_type "> consent policy: OWN DATA / WRITTEN CONSENT ONLY" 0.01
  printf "${_N}"; echo
  boot_log
  echo
  hex_stream 12
  echo
  bar "decrypting modules"
  sleep 0.3
  clear

  decrypt_line " ████████╗██████╗  █████╗  ██████╗███████╗██╗  ██╗██╗████████╗"
  decrypt_line " ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║ ██╔╝██║╚══██╔══╝"
  decrypt_line "    ██║   ██████╔╝███████║██║     █████╗  █████╔╝ ██║   ██║   "
  decrypt_line "    ██║   ██╔══██╗██╔══██║██║     ██╔══╝  ██╔═██╗ ██║   ██║   "
  decrypt_line "    ██║   ██║  ██║██║  ██║╚██████╗███████╗██║  ██╗██║   ██║   "
  decrypt_line "    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝   "
  echo
  printf "${_Y}        "; tk_type "Educational OSINT Toolkit  |  Own data or consent only" 0.02; printf "${_N}"
  echo
  local i
  for i in 1 2 3; do
    printf "\r        ${_BG}[ ACCESS GRANTED ]${_N}"; sleep 0.25
    printf "\r                           "; sleep 0.12
  done
  printf "\r        ${_BG}[ ACCESS GRANTED ]${_N}\n"
  sleep 0.8
  tput cnorm 2>/dev/null
}
