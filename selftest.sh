#!/bin/bash
cd "$(dirname "$0")"
n=$(grep -c "print_menu" tracekit.sh)
[ "$n" = 1 ] && echo "OK  menu printed once" || echo "FAIL print_menu appears $n times"
for f in *.sh; do bash -n "$f" || echo "FAIL syntax $f"; done
echo "syntax check done"
