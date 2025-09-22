#!/usr/bin/env sh
set -eu

echo "==> 0) Disable App Router (use Pages Router only)"
if [ -d app ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  mv app "app.disabled.$TS"
  echo "• moved app/ -> app.disabled.$TS"
else
  echo "• no app/ dir; nothing to move"
fi

echo "==> 1) Write .env.local"
cat > .env.local <<'EOV'
NEXT_PUBLIC_SUPABASE_URL=https://glgcnymigakooloqmbtk.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZ2NueW1pZ2Frb29sb3FtYnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczNjEwNTgsImV4cCI6MjA3MjkzNzA1OH0.Dh7JrFVVhcVyG9mckwqDlQzzRkbFaQhFQ8QdK_bpkeQ
EOV
echo "✓ wrote .env.local"

echo "==> 2) Browser-only Supabase helper"
mkdir -p lib
if [ -f lib/supabase-browser.ts ]; then cp lib/supabase-browser.ts "lib/supabase-browser.ts.bak.$(date +%s)"; fi
cat > lib/supabase-browser.ts <<'EOV'
'use client';
import { createBrowserClient } from '@supabase/ssr';

export const supabaseBrowser = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get: (key: string) => {
          if (typeof document === 'undefined') return '';
          const m = document.cookie.match(`(^| )${key}=([^;]+)`);
          return m ? decodeURIComponent(m[2]) : '';
        },
      },
    }
  );
EOV
echo "✓ lib/supabase-browser.ts"

echo "==> 3) Shim legacy supabaseClient.js (if present)"
if [ -f supabaseClient.js ]; then
  cp supabaseClient.js "supabaseClient.js.bak.$(date +%s)" || true
  cat > supabaseClient.js <<'EOV'
// Legacy shim -> use the browser helper
"use client";
const { supabaseBrowser } = require("./lib/supabase-browser");
module.exports = { supabaseBrowser };
EOV
  echo "✓ supabaseClient.js shimmed"
else
  echo "• no supabaseClient.js (good)"
fi

echo "==> 4) Client-only /pages/activity-log.tsx"
mkdir -p pages
if [ -f pages/activity-log.tsx ]; then cp pages/activity-log.tsx "pages/activity-log.tsx.bak.$(date +%s)"; fi
cat > pages/activity-log.tsx <<'EOV'
import React, { useMemo, useEffect, useState } from 'react';
import { supabaseBrowser } from '@/lib/supabase-browser';

export default function ActivityLogPage() {
  const supabase = useMemo(() => supabaseBrowser(), []);
  const [rows, setRows] = useState<any[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data, error } = await supabase
          .from('activity_log') // TODO: replace with your real table/view
          .select('*')
          .limit(50);
        if (!cancelled) {
          if (error) throw error;
          setRows(data ?? []);
        }
      } catch (e: any) {
        if (!cancelled) setErr(e?.message || String(e));
        console.error('Activity log fetch failed:', e);
      }
    })();
    return () => { cancelled = true; };
  }, [supabase]);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <h1>Activity Log</h1>
      {err && <p style={{ color: 'crimson' }}>Error: {err}</p>}
      <pre style={{ whiteSpace: 'pre-wrap', background: '#f6f6f6', padding: 12, borderRadius: 8 }}>
        {JSON.stringify(rows, null, 2)}
      </pre>
    </main>
  );
}
EOV
echo "✓ pages/activity-log.tsx"

echo "==> 5) Clean and build"
rm -rf .next
npm run build
