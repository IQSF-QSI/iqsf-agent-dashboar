#!/usr/bin/env zsh
set -euo pipefail
setopt nonomatch   # don't error if a glob doesn't match
unsetopt nomatch   # (alias of above on some setups)

print "==> 1) Writing .env.local"
cat > .env.local <<'EOV'
NEXT_PUBLIC_SUPABASE_URL=https://glgcnymigakooloqmbtk.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZ2NueW1pZ2Frb29sb3FtYnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczNjEwNTgsImV4cCI6MjA3MjkzNzA1OH0.Dh7JrFVVhcVyG9mckwqDlQzzRkbFaQhFQ8QdK_bpkeQ
EOV
print "✓ .env.local ready"

print "==> 2) Ensure browser-only Supabase helper exists"
mkdir -p lib
if [ ! -f lib/supabase-browser.ts ]; then
  cat > lib/supabase-browser.ts <<'EOV'
'use client';
import { createBrowserClient } from '@supabase/ssr';

export const supabaseBrowser = () => {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get: (key: string) => {
          if (typeof document === 'undefined') return '';
          const match = document.cookie.match(`(^| )${key}=([^;]+)`);
          return match ? decodeURIComponent(match[2]) : '';
        },
      },
    }
  );
};
EOV
  print "✓ lib/supabase-browser.ts created"
else
  print "• lib/supabase-browser.ts already present"
fi

print "==> 3) Make /activity-log a client-only, dynamic page (no SSR)"
mkdir -p app/activity-log
if [ -f app/activity-log/page.tsx ]; then
  cp app/activity-log/page.tsx app/activity-log/page.tsx.bak.$(date +%s) || true
fi
cat > app/activity-log/page.tsx <<'EOV'
'use client';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

import { useMemo, useEffect, useState } from 'react';
import { supabaseBrowser } from '@/lib/supabase-browser';

export default function ActivityLog() {
  const supabase = useMemo(() => supabaseBrowser(), []);
  const [rows, setRows] = useState<any[]>([]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data, error } = await supabase.from('activity_log').select('*').limit(50);
        if (!cancelled) {
          if (error) throw error;
          setRows(data ?? []);
        }
      } catch (e) {
        console.error('ActivityLog fetch failed:', e);
      }
    })();
    return () => { cancelled = true; };
  }, [supabase]);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <h1>Activity Log</h1>
      <p style={{ opacity: 0.7, marginBottom: 12 }}>Client-only, dynamic page (no SSR)</p>
      <pre style={{ whiteSpace: 'pre-wrap', background: '#f6f6f6', padding: 12, borderRadius: 8 }}>
        {JSON.stringify(rows, null, 2)}
      </pre>
    </main>
  );
}
EOV
print "✓ app/activity-log/page.tsx written"

print "==> 4) Add 'use client' where the browser client is imported"
USERS=$(grep -RIl '@/lib/supabase-browser' app components pages 2>/dev/null || true)
for f in $USERS; do
  if [ -f "$f" ]; then
    first=$(head -n1 "$f" || echo '')
    if ! print -- "$first" | grep -q "use client"; then
      cp "$f" "$f.bak.$(date +%s)" || true
      { print "'use client'"; cat "$f"; } > "$f.__tmp__" && mv "$f.__tmp__" "$f"
      print "  • added 'use client' -> $f"
    fi
  fi
done

print "==> 5) Scan for risky patterns (FYI only; fix if anything prints)"
print "-- top-level createClient/supabaseBrowser (should be inside a component/useMemo) --"
grep -RIn 'createBrowserClient\s*\(' app components pages 2>/dev/null | awk '!/useMemo|useEffect|function|=>/'
grep -RIn 'supabaseBrowser\s*\(' app components pages 2>/dev/null | awk '!/useMemo|useEffect/'

print "-- server layouts using supabase client (avoid) --"
grep -RIn '@supabase/supabase-js' app 2>/dev/null || true
grep -RIn 'supabaseBrowser' app/*/layout.* app/layout.* 2>/dev/null || true

print "==> 6) Build"
npm run build
