#!/usr/bin/env bash
# Copia SOLO los archivos públicos a .cf-publicar/ (lo que Cloudflare publica desde GitHub).
# Cloudflare lo ejecuta como «Build command»; después publica con «npx wrangler deploy».
set -euo pipefail
cd "$(dirname "$0")/.."
ORIGEN="."
rm -rf ./.cf-publicar
mkdir ./.cf-publicar
tar -cf - -C "$ORIGEN" \
  --exclude='./tools' --exclude='./scripts' --exclude='./.git' --exclude='./.vercel' --exclude='./node_modules' --exclude='./.claude' \
  --exclude='*.md' --exclude='.env*' --exclude='.DS_Store' --exclude='./.htaccess' --exclude='./assets/photos/source' \
  --exclude='./.gitignore' --exclude='./.vercelignore' --exclude='./vercel.json' --exclude='./wrangler.jsonc' --exclude='./.cf-publicar' \
  . | tar -xf - -C ./.cf-publicar
printf '/*\n  X-Content-Type-Options: nosniff\n  Referrer-Policy: strict-origin-when-cross-origin\n  Strict-Transport-Security: max-age=63072000; includeSubDomains\n' > ./.cf-publicar/_headers
echo "Listo para publicar: $(find ./.cf-publicar -type f | wc -l | tr -d ' ') archivos"
