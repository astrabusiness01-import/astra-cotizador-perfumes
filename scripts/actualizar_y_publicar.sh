#!/bin/bash
# Actualiza el catálogo desde Crist y, si cambió, lo publica.
# Al subir a GitHub se publica solo en Cloudflare (y en Vercel mientras siga).
# Si un día no hubo internet, lo pendiente se sube en la siguiente ejecución.
cd "$(dirname "$0")/.." || exit 1
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"
echo "=== $(date) ==="
/usr/bin/python3 scripts/refresh_catalog.py || { echo "Falló la descarga; no se publica nada."; exit 1; }
if ! git diff --quiet -- data/products.json; then
  git add data/products.json
  git commit -q -m "Catálogo actualizado automáticamente $(date +%Y-%m-%d)"
fi
# Trae lo nuevo de GitHub antes de subir (por si se cambió algo desde otro lugar)
git pull -q --rebase origin main || { echo "No se pudo traer lo nuevo de GitHub; se reintenta mañana."; git rebase --abort 2>/dev/null; exit 1; }
if [ "$(git rev-list --count origin/main..HEAD)" -gt 0 ]; then
  git push -q origin main && echo "Publicado." || echo "No se pudo subir; se reintenta mañana."
else
  echo "Sin cambios."
fi
