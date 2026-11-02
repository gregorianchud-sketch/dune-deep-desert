#!/usr/bin/env python3
"""Scrape the Method.gg Deep Desert Companion into assets/data/deep_desert.json.

Only data present on the page is extracted; nothing is invented.
Exits non-zero (without touching the output) if the scrape looks broken.
"""
import json, re, sys, datetime, pathlib
import requests
from bs4 import BeautifulSoup

URL = "https://www.method.gg/dune-awakening/deep-desert-companion"
BASE = "https://www.method.gg"
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets/data/deep_desert.json"
MODES = {"multiplayer": "Standard", "singleplayer": "Single Player"}


def absu(u):
    return u if not u or u.startswith("http") else BASE + u


def txt(el):
    return re.sub(r"\s+", " ", el.get_text(" ", strip=True)).strip() if el else ""


def parse_tooltip(html):
    t = BeautifulSoup(html, "html.parser")
    d = {"name": txt(t.select_one(".pin-name")), "details": {}, "thumbnail": None,
         "loot_preview": {}}
    img = t.select_one(".pin-image img")
    if img:
        d["thumbnail"] = absu(img.get("src"))
    current = None
    for tip in t.select(".pin-tip"):
        b = tip.find("b")
        if b:
            current = txt(b)
            d["loot_preview"][current] = {"items": [], "more": None}
            continue
        lab = tip.select_one(".pin-tip-label")
        s = txt(tip)
        if lab:
            k = txt(lab).rstrip(":")
            v = s[len(txt(lab)):].strip()
            if current:
                d["loot_preview"][current]["items"].append({"name": k, "chance": v})
            else:
                d["details"][k] = v
        elif s:
            m = re.match(r"and (\d+) more", s)
            if m and current:
                d["loot_preview"][current]["more"] = int(m.group(1))
            elif not s.lower().startswith("full list"):
                d.setdefault("notes", []).append(s)
    return d


def parse_grid(pane):
    g = pane.select_one(".grid-wrapper")
    m = re.search(r"url\('([^']+)'\)", g.get("style", ""))
    cols = [txt(a) for a in g.select(".axis-label") if txt(a).isdigit()]
    cols = sorted(set(cols), key=int)
    rows, pois = [], []
    for cell in g.select(".main-cell"):
        r, c = cell["data-main-cell"].split(":")
        if r not in rows:
            rows.append(r)
        for w in cell.select(".grid-icon-wrap"):
            tip = parse_tooltip(w.get("data-content", ""))
            a = w.select_one("a")
            icon = w.select_one("img")
            pois.append({
                "name": tip["name"], "type": w.get("data-poitype"),
                "grid": f"{r}{c}", "row": r, "col": int(c),
                "sub_x": int(w.get("data-subx", 2)), "sub_y": int(w.get("data-suby", 2)),
                "details": tip["details"], "notes": tip.get("notes", []),
                "loot_preview": tip["loot_preview"], "thumbnail": tip["thumbnail"],
                "guide_url": absu(a.get("href")) if a else None,
                "icon_url": absu(icon.get("src")) if icon else None,
            })
    filters = [{"type": f.get("data-type"), "label": f.get("title"),
                "icon_url": absu(f.select_one("img").get("src")) if f.select_one("img") else None}
               for f in pane.select(".grid-filter-btn")]
    return {"map_image_url": absu(m.group(1)) if m else None,
            "grid": {"rows": rows, "cols": [int(c) for c in cols], "subdivisions": 3,
                     "row_order": "top-to-bottom"},
            "filters": filters, "pois": pois}


def parse_loot(wrapper):
    sections = []
    for sec in wrapper.select(".loot-section-block"):
        cls = [c for c in sec.get("class", []) if c.startswith("loot-section-type-")]
        stype = cls[0].replace("loot-section-type-", "") if cls else ""
        items = []
        for tile in sec.select(".loot-tile"):
            tier = tile.select_one(".loot-tier-list")
            link = tile.select_one(".loot-tile-link")
            img = tile.select_one(".loot-tile-image img")
            sources = []
            for s in tile.select(".loot-poi-str > div"):
                st = [c.replace("loot-poi-str-type-", "") for c in s.get("class", [])]
                sources.append({"poi": txt(s.select_one(".loot-poi-str__name")),
                                "type": st[0] if st else None,
                                "chance": txt(s.select_one(".loot-poi-str__drop"))})
            items.append({
                "name": txt(tile.select_one(".loot-name")),
                "category": txt(tile.select_one(".loot-type")),
                "tier": txt(tier) or None,
                "drop_chance": txt(tile.select_one(".loot-drop-chance")) or None,
                "icon_url": absu(img.get("src")) if img else None,
                "url": absu(link.get("href")) if link else None,
                "sources": sources,
            })
        sections.append({"title": txt(sec.select_one(".loot-section-title")),
                         "type": stype or None,
                         "row_a_collapsed": "collapse" in (sec.parent.get("class") or []),
                         "items": items})
    return sections


def main():
    r = requests.get(URL, headers={"User-Agent": "Mozilla/5.0 (dd-app scraper)"}, timeout=60)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    content = soup.select_one(".news-content-list") or soup
    week = None
    lab = content.find(string=re.compile(r"Updated for:"))
    if lab:
        nxt = lab.find_next(string=lambda s: s and s.strip() and "Updated for" not in s)
        week = nxt.strip() if nxt else None
    intro = soup.select_one("meta[name=description]")
    data = {"source": URL, "source_name": "Method.gg Deep Desert Companion",
            "scraped_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
            "week_label": week, "maps": {}, "endgame_notes": []}
    for pid, label in MODES.items():
        pane = content.select_one(f".tab-pane#{pid}")
        if not pane:
            continue
        m = parse_grid(pane)
        m["label"] = label
        m["loot"] = {}
        for w in pane.select(".loot-tables-wrapper"):
            m["loot"][w.get("data-loot", "pve")] = parse_loot(w)
        data["maps"][pid] = m
    # End-game notes: informational sentences on the page (verbatim).
    full = txt(content)
    pats = [r"In the PVP instance of the Deep Desert, mining yields and spice harvesting is increased by \d+%",
            r"On Single Player, the Deep Desert does not reset with the Coriolis Storm[^.]*\.",
            r"Row A \(Mk5\) loot tables are at the bottom \(collapsed\)\.",
            r"The loot tables below contain all of the Unique Schematics that are available from the Deep Desert each week\.",
            r"Updated shortly after the reset each week\.",
            r"Try switching the map view from Normal to Detailed[^.]*\."]
    for p in pats:
        mm = re.search(p, full.replace(" .", ".").replace(" ,", ","))
        if mm and mm.group(0) not in data["endgame_notes"]:
            data["endgame_notes"].append(mm.group(0).rstrip(".") + ".")
    for mp in data["maps"].values():
        for p in mp["pois"]:
            for k, v in p["details"].items():
                pass
    std = data["maps"].get("multiplayer")
    if not std or len(std["pois"]) < 10 or not std["loot"].get("pve"):
        print("Scrape looks broken; not writing output", file=sys.stderr)
        sys.exit(2)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1))
    print(f"Wrote {OUT} week={week} pois=" + ",".join(f"{k}:{len(v['pois'])}" for k, v in data["maps"].items()))


if __name__ == "__main__":
    main()
