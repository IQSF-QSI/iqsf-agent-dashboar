#!/usr/bin/env sh
set -eu

echo "==> 1) Create shared shim component"
mkdir -p components
cat > components/HomeShim.tsx <<'EOC'
export default function HomeShim(){ return null; }
EOC

echo "==> 2) Rewrite any imports of ../../app/page.js -> ../../components/HomeShim"
# Find JS/TS files that import any path like ../.../app/page.js (any depth of ../)
FILES=$(grep -RIl "['\"]\(\.\./\)\+app/page\.js['\"]" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' . 2>/dev/null || true)

for f in $FILES; do
  cp "$f" "$f.bak_$(date +%s)" || true
  # macOS sed first; fallback to GNU sed
  sed -E -i '' "s#(['\"])((\.\./)+)app/page\.js(['\"])#\1\2components/HomeShim\4#g" "$f" 2>/dev/null || \
  sed -E -i    "s#(['\"])((\.\./)+)app/page\.js(['\"])#\1\2components/HomeShim\4#g" "$f"
  echo "• rewrote import in $f"
done

echo "==> 3) Remove App Router root page to eliminate route conflict"
rm -f app/page.js 2>/dev/null || true

echo "==> 4) Clean and build"
rm -rf .next
npm run build
