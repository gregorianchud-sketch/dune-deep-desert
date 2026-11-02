"""Generate the app icon (original artwork) as SVG and render 1024px PNG.
Requires cairosvg (pip install cairosvg)."""
import math, random, pathlib
root = pathlib.Path(__file__).resolve().parent.parent / "assets/icon"
random.seed(7)
S = 1024; C = S / 2
out = []
a = out.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">')
a('''<defs>
<radialGradient id="sky" cx="50%" cy="78%" r="80%">
 <stop offset="0" stop-color="#ff9a3c"/><stop offset="0.25" stop-color="#b4471a"/>
 <stop offset="0.55" stop-color="#3a1c2c"/><stop offset="1" stop-color="#070b1c"/></radialGradient>
<radialGradient id="moonA" cx="40%" cy="40%" r="65%"><stop offset="0" stop-color="#fff4dc"/><stop offset="1" stop-color="#e3b98a"/></radialGradient>
<radialGradient id="moonB" cx="40%" cy="40%" r="65%"><stop offset="0" stop-color="#f6e7ff"/><stop offset="1" stop-color="#b9a3c9"/></radialGradient>
<radialGradient id="mglow"><stop offset="0" stop-color="#ffe2a8" stop-opacity="0.55"/><stop offset="1" stop-color="#ffe2a8" stop-opacity="0"/></radialGradient>
<linearGradient id="dune1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9893a"/><stop offset="1" stop-color="#6b3413"/></linearGradient>
<linearGradient id="dune2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a95a24"/><stop offset="1" stop-color="#3d1d0b"/></linearGradient>
<linearGradient id="dune3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6e3816"/><stop offset="1" stop-color="#1b0d06"/></linearGradient>
<linearGradient id="body" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3b2312"/><stop offset="0.45" stop-color="#a8743a"/><stop offset="0.6" stop-color="#c99150"/><stop offset="1" stop-color="#2c190c"/></linearGradient>
<radialGradient id="throat"><stop offset="0" stop-color="#ffcf5a"/><stop offset="0.18" stop-color="#ff8a1f"/><stop offset="0.5" stop-color="#5a1606"/><stop offset="1" stop-color="#120503"/></radialGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff1b0"/><stop offset="0.5" stop-color="#f2b437"/><stop offset="1" stop-color="#9a5a10"/></linearGradient>
<linearGradient id="bronze" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f3c77c"/><stop offset="0.3" stop-color="#9a6326"/><stop offset="0.55" stop-color="#e2a85a"/><stop offset="0.8" stop-color="#6e4115"/><stop offset="1" stop-color="#d79b4d"/></linearGradient>
<radialGradient id="spiceglow"><stop offset="0" stop-color="#ffb547" stop-opacity="0.7"/><stop offset="1" stop-color="#ff7a1a" stop-opacity="0"/></radialGradient>
<filter id="blur"><feGaussianBlur stdDeviation="10"/></filter>
<clipPath id="disc"><circle cx="512" cy="512" r="430"/></clipPath>
</defs>''')
a('<rect width="1024" height="1024" fill="#0b0705"/>')
a('<g clip-path="url(#disc)">')
a('<rect width="1024" height="1024" fill="url(#sky)"/>')
for _ in range(90):
    x, y = random.uniform(90, 934), random.uniform(90, 520)
    a(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{random.uniform(0.8,2.6):.1f}" fill="#fff6e0" opacity="{random.uniform(0.3,0.9):.2f}"/>')
# twin moons
a('<circle cx="330" cy="250" r="150" fill="url(#mglow)"/><circle cx="330" cy="250" r="74" fill="url(#moonA)"/>')
a('<circle cx="305" cy="232" r="12" fill="#d8ab7a" opacity="0.5"/><circle cx="352" cy="275" r="9" fill="#d8ab7a" opacity="0.45"/>')
a('<circle cx="720" cy="200" r="90" fill="url(#mglow)"/><circle cx="720" cy="200" r="38" fill="url(#moonB)"/>')
# far dunes
a('<path d="M0 640 C150 560 300 600 430 590 C560 580 700 520 1024 600 L1024 1024 L0 1024Z" fill="url(#dune1)" opacity="0.9"/>')
# spice glow behind worm
a('<ellipse cx="512" cy="560" rx="300" ry="240" fill="url(#spiceglow)"/>')
# worm body: rising curve from dunes, slightly leaning
a('<path d="M380 860 C370 720 400 560 420 470 L604 470 C624 560 660 720 650 860 Z" fill="url(#body)"/>')
for i in range(9):
    y = 500 + i * 42
    w = 92 + i * 6
    a(f'<path d="M{512-w} {y} Q512 {y+22} {512+w} {y}" stroke="#2a170a" stroke-width="5" fill="none" opacity="0.55"/>')
    a(f'<path d="M{512-w+6} {y+6} Q512 {y+26} {512+w-6} {y+6}" stroke="#e3ad66" stroke-width="2" fill="none" opacity="0.35"/>')
# maw: ellipse opening facing viewer
cx, cy, rx, ry = 512, 400, 170, 150
a(f'<ellipse cx="{cx}" cy="{cy+14}" rx="{rx+22}" ry="{ry+20}" fill="#2a170a"/>')
# lip petals
for k in range(12):
    t = 2*math.pi*k/12
    x, y = cx + (rx+14)*math.cos(t), cy + (ry+12)*math.sin(t)
    a(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="46" ry="30" transform="rotate({math.degrees(t)+90:.1f} {x:.1f} {y:.1f})" fill="url(#body)" stroke="#1b0e05" stroke-width="3"/>')
a(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#throat)"/>')
# layered teeth rings
for ring, (scale, n, L, op) in enumerate([(1.0, 36, 46, 1), (0.74, 28, 38, 0.95), (0.5, 22, 30, 0.9), (0.3, 16, 20, 0.85)]):
    for k in range(n):
        t = 2*math.pi*(k + 0.5*ring)/n
        bx, by = cx + rx*scale*math.cos(t), cy + ry*scale*math.sin(t)
        tx, ty = cx + (rx*scale - L)*math.cos(t), cy + (ry*scale - L*0.9)*math.sin(t)
        half = math.pi/n*0.9
        x1, y1 = cx + rx*scale*math.cos(t-half), cy + ry*scale*math.sin(t-half)
        x2, y2 = cx + rx*scale*math.cos(t+half), cy + ry*scale*math.sin(t+half)
        a(f'<path d="M{x1:.1f} {y1:.1f} L{tx:.1f} {ty:.1f} L{x2:.1f} {y2:.1f} Z" fill="url(#gold)" stroke="#6b3a08" stroke-width="1.2" opacity="{op}"/>')
a(f'<ellipse cx="{cx}" cy="{cy}" rx="34" ry="30" fill="#ffd36a" filter="url(#blur)"/>')
# near dunes in front of worm
a('<path d="M0 800 C180 720 330 790 470 770 C620 750 760 690 1024 760 L1024 1024 L0 1024Z" fill="url(#dune2)"/>')
a('<path d="M0 900 C220 840 420 900 600 880 C780 860 900 830 1024 870 L1024 1024 L0 1024Z" fill="url(#dune3)"/>')
a('<path d="M120 812 C260 760 380 800 470 772" stroke="#f0b067" stroke-width="3" fill="none" opacity="0.5"/>')
# spice motes
for _ in range(40):
    x, y = random.uniform(300, 720), random.uniform(560, 860)
    a(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{random.uniform(1.5,4):.1f}" fill="#ffb547" opacity="{random.uniform(0.3,0.9):.2f}"/>')
a('</g>')
# ornate bronze bezel
a('<circle cx="512" cy="512" r="452" fill="none" stroke="url(#bronze)" stroke-width="40"/>')
a('<circle cx="512" cy="512" r="474" fill="none" stroke="#4a2a0c" stroke-width="4"/>')
a('<circle cx="512" cy="512" r="430" fill="none" stroke="#4a2a0c" stroke-width="4"/>')
for k in range(48):
    t = 2*math.pi*k/48
    r1, r2 = 440, 464 if k % 4 else 470
    a(f'<line x1="{C+r1*math.cos(t):.1f}" y1="{C+r1*math.sin(t):.1f}" x2="{C+r2*math.cos(t):.1f}" y2="{C+r2*math.sin(t):.1f}" stroke="#5a330e" stroke-width="{4 if k%4==0 else 2}"/>')
for k in range(8):
    t = 2*math.pi*k/8 + math.pi/8
    x, y = C+452*math.cos(t), C+452*math.sin(t)
    a(f'<path d="M{x:.1f} {y-14:.1f} L{x+12:.1f} {y:.1f} L{x:.1f} {y+14:.1f} L{x-12:.1f} {y:.1f}Z" fill="url(#gold)" stroke="#4a2a0c" stroke-width="2" transform="rotate({math.degrees(t):.1f} {x:.1f} {y:.1f})"/>')
a('</svg>')
svg = "\n".join(out)
(root / "icon.svg").write_text(svg)
import cairosvg
cairosvg.svg2png(bytestring=svg.encode(), write_to=str(root / "icon.png"), output_width=1024, output_height=1024)
print("ok")
