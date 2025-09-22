#!/usr/bin/env sh
set -eu

echo "==> Create minimal app/page.js to satisfy imports"
mkdir -p app
cat > app/page.js <<'EOV'
// Minimal stub to satisfy imports like ../../app/page.js during migration.
export const dynamic = 'force-static';
export const revalidate = false;
export default function HomeShim(){ return null; }
EOV

echo "==> Clean and build"
rm -rf .next
npm run build
