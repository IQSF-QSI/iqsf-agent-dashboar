#!/usr/bin/env sh
set -eu

FILE="pages/activity-log.tsx"
[ -f "$FILE" ] || { echo "Not found: $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_$(date +%s)" || true

# Replace "setErr(e?.message || String(e));" with a safe Error guarding pattern.
awk '
  {
    if ($0 ~ /setErr\(e\?\.[mM]essage \|\| String\(e\)\);/) {
      print "        const msg = e instanceof Error ? e.message : String(e);";
      print "        if (!cancelled) setErr(msg);";
    } else {
      print $0
    }
  }
' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"

# Clean and build
rm -rf .next
npm run build
