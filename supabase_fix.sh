#!/usr/bin/env sh
set -eu

echo "==> Write lib/supabase-browser.ts (uses @supabase/supabase-js only)"
mkdir -p lib
cat > lib/supabase-browser.ts <<'EOTS'
'use client';
import { createClient } from '@supabase/supabase-js';

export const supabaseBrowser = () => {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  if (!url || !anon) throw new Error('NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are required');
  return createClient(url, anon, { auth: { persistSession: true, autoRefreshToken: true } });
};
EOTS

echo "==> Fix pages/activity-log.tsx import path"
if [ -f pages/activity-log.tsx ]; then
  cp pages/activity-log.tsx "pages/activity-log.tsx.bak_$(date +%s)" || true
  # macOS BSD sed first; if it fails, try GNU sed
  sed -i '' "s#from '@/lib/supabase-browser'#from '../lib/supabase-browser'#" pages/activity-log.tsx 2>/dev/null || \
  sed -i "s#from '@/lib/supabase-browser'#from '../lib/supabase-browser'#" pages/activity-log.tsx || true
fi

echo "==> Ensure @supabase/supabase-js is installed"
npm ls @supabase/supabase-js >/dev/null 2>&1 || npm install @supabase/supabase-js

echo "==> Clean and build"
rm -rf .next
npm run build
