# run_tool <name> <outfile> <command...>  -> logs status to $OUT/_status.tsv
run_tool() {
  local name="$1" file="$2"; shift 2
  local start end rc status
  echo "[$name]"
  start=$(date +%s)
  timeout "${TOOL_TIMEOUT:-300}" "$@" 2>&1 | tee "$file"
  rc=${PIPESTATUS[0]}
  end=$(date +%s)
  if   [ "$rc" = 124 ]; then status="TIMEOUT"
  elif [ "$rc" != 0 ];  then status="FAILED"
  elif [ ! -s "$file" ]; then status="EMPTY"
  else status="OK"; fi
  printf '%s\t%s\t%ss\n' "$name" "$status" "$((end-start))" >> "$(dirname "$file")/_status.tsv"
}
