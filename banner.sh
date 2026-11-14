# TraceKit banner, sourced by tracekit.sh
banner() {
  load_theme
  clear
  local i=0 line
  while IFS= read -r line; do
    printf '%s%s%s\n' "$(fg ${LOGO[i]})" "$line" "$NC"
    i=$((i+1))
  done <<'ART'
 ████████╗██████╗  █████╗  ██████╗███████╗██╗  ██╗██╗████████╗
 ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║ ██╔╝██║╚══██╔══╝
    ██║   ██████╔╝███████║██║     █████╗  █████╔╝ ██║   ██║
    ██║   ██╔══██╗██╔══██║██║     ██╔══╝  ██╔═██╗ ██║   ██║
    ██║   ██║  ██║██║  ██║╚██████╗███████╗██║  ██╗██║   ██║
    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝
ART
  printf '%s        Educational OSINT Toolkit  |  Own data or consent only%s\n' "$(fg $ACC)" "$NC"
  printf '\033[38;5;240m        ─────────────────────────────────────────────%s\n\n' "$NC"
}
