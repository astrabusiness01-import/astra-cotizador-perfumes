#!/bin/bash
# Actualiza el catálogo desde Crist y, si cambió, lo publica (Vercel redeploya solo al hacer push).
cd "$(dirname "$0")/.." || exit 1
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"
echo "=== $(date) ==="
/usr/bin/python3 scripts/refresh_catalog.py || { echo "Falló la descarga; no se publica nada."; exit 1; }
if git diff --quiet -- data/products.json; then echo "Sin cambios."; exit 0; fi
git add data/products.json
git commit -q -m "Catálogo actualizado automáticamente $(date +%Y-%m-%d)"
git push -q origin main && echo "Publicado."
