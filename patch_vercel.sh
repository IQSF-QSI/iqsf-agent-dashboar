#!/usr/bin/env bash
set -euo pipefail

timestamp="$(date +%Y%m%d-%H%M%S)"

backup_if_exists () {
  local file="$1"
  if [ -f "$file" ]; then
    mv "$file" "$file.bak.$timestamp"
    echo "• Backed up $file -> $file.bak.$timestamp"
  fi
}

ensure_dir () { mkdir -p "$1"; }

echo "==> Patching repo for Vercel + Next.js + Supabase…"

# 1) .env.example
backup_if_exists ".env.example"
cat > .env.example <<'EOD'
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
# SUPABASE_SERVICE_ROLE_KEY=service-role-if-needed
EOD

# ... (rest of script as previously provided) ...

echo "==> Patch complete."
