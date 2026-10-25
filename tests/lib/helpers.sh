# tests/lib/helpers.sh — verdict helpers with counter-driven check numbers.
# sourced by tests/check.sh; cwd is repo root.
G=/usr/bin/grep           # absolute path: bypasses the rtk hook that rewrites bare grep

n=0; pass=0; fail=0; warn=0
ok()  { n=$((n+1)); pass=$((pass+1)); echo "PASS $n: $1"; }
bad() { n=$((n+1)); fail=$((fail+1)); echo "FAIL $n: $1"; }
wn()  { n=$((n+1)); warn=$((warn+1)); echo "WARN $n: $1"; }