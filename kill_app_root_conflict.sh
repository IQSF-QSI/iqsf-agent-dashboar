#!/usr/bin/env sh
set -eu

echo "==> Find App Router files that match '/'"
if [ -d app ]; then
  echo "Potential culprits:"
  # Any page.* at root or inside () group segments match '/'
  find app -type f \( -name 'page.*' -o -name 'layout.*' \) | sed 's/^/  - /' || true
else
  echo "No app/ directory found."
fi

echo "==> Remove the entire app/ directory to eliminate conflicts"
rm -rf app

echo "==> Ensure Pages Router home exists (redirect to /dashboard)"
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

echo "==> Clean and rebuild"
rm -rf .next
npm run build
