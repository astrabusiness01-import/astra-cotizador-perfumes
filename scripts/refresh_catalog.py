#!/usr/bin/env python3
"""Descarga el catálogo público de wholesale.cristfragances.com y regenera data/products.json.

Esquema por variante: {id, t, p, v, a, im}. Reutiliza las miniaturas ya descargadas
(por producto) y solo baja las de productos nuevos.
"""
import base64, concurrent.futures, json, os, sys, urllib.request

BASE = "https://wholesale.cristfragances.com"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "products.json")
UA = {"User-Agent": "Mozilla/5.0"}

def get(url, timeout=30):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout) as r:
        return r.read(), r.headers.get("Content-Type", "image/jpeg")

products = []
page = 1
while True:
    data, _ = get(f"{BASE}/products.json?limit=250&page={page}")
    batch = json.loads(data).get("products", [])
    if not batch:
        break
    products.extend(batch)
    page += 1
if len(products) < 1000:
    sys.exit(f"Solo {len(products)} productos: el sitio parece caído, no se actualiza nada.")

old = {}
if os.path.exists(OUT):
    for it in json.load(open(OUT, encoding="utf-8")):
        old[it["id"]] = it.get("im")

items, pid_of, seen = [], {}, set()
for p in products:
    title = p["title"].strip()
    for v in p["variants"]:
        if v["id"] in seen:
            continue
        seen.add(v["id"])
        vt = v.get("title")
        full = title if (not vt or vt == "Default Title" or vt == title) else f"{title} - {vt}"
        try:
            price = float(v["price"])
        except (TypeError, ValueError):
            continue
        items.append({"id": v["id"], "t": full, "p": price,
                      "v": (p.get("vendor") or "").strip(), "a": bool(v.get("available"))})
        pid_of[v["id"]] = p["id"]

img_by_pid = {}
for it in items:
    if old.get(it["id"]):
        img_by_pid.setdefault(pid_of[it["id"]], old[it["id"]])

need = {p["id"]: p["images"][0]["src"] for p in products
        if p["id"] not in img_by_pid and p.get("images")}

def thumb(pid_url):
    pid, url = pid_url
    u = url + ("&" if "?" in url else "?") + "width=64"
    try:
        raw, ctype = get(u, 15)
        return pid, f"data:{ctype};base64," + base64.b64encode(raw).decode()
    except Exception:
        return pid, None

with concurrent.futures.ThreadPoolExecutor(max_workers=40) as ex:
    for pid, im in ex.map(thumb, need.items()):
        if im:
            img_by_pid[pid] = im

for it in items:
    im = img_by_pid.get(pid_of[it["id"]])
    if im:
        it["im"] = im

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(items, f, ensure_ascii=False)
size = os.path.getsize(OUT) / 1024 / 1024
print(f"{len(items)} variantes, {len(need)} imágenes nuevas, {size:.1f} MB")
if size > 15:
    sys.exit("Archivo > 15 MB: reducir width de miniaturas")
