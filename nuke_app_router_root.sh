#!/usr/bin/env sh
set -eu

echo "==> Find ALL app router roots (excluding node_modules)"
find . -path './node_modules' -prune -o -type d -name app -print

echo "==> Show page/layout files inside any app dirs"
find . -path './node_modules' -prune -o -type d -name app -exec sh -c '
  for d do
    echo "  -- $d"
    find "$d" -type f \( -name "page.*" -o -name "layout.*" \) -maxdepth 2 -print
  done
' sh {} +

echo "==> Remove all app dirs to eliminate App Router (use Pages Router only)"
# Remove ./app and ./src/app if they exist
rm -rf ./app ./src/app

# Safety: also remove any lingering backups that Next might still scan
rm -rf ./app.disabled.* ./src/app.disabled.*

echo "==> Ensure Pages Router home exists and redirects to /dashboard"
mkdir -p pages
if [ ! -f pages/index.tsx ]; then
  cat > pages/index.tsx <<'EOV'
import { useEffect } from 'react';
import { useRouter } from 'next/router';
export default function Home() {
  const router = useRouter();
  useEffect(() => { router.replace('/dashboard'); }, [router]);
  return null;
}
EOV
fi

echo "==> Clean Next cache and rebuild"
rm -rf .next
npm run build
