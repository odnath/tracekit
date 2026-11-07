#!/usr/bin/env python3
"""Build report.html from a run.sh output folder. Usage: make_report.py <output_folder>"""
import sys, html, pathlib, datetime

out = pathlib.Path(sys.argv[1])
esc = html.escape

def read(name):
    p = out / name
    return p.read_text(errors="replace") if p.exists() else ""

# 1. phonenumbers
basic = [l for l in read("phonenumbers.txt").splitlines() if ":" in l]
basic_rows = "".join(
    f"<tr><th>{esc(k.strip())}</th><td>{esc(v.strip())}</td></tr>"
    for k, v in (l.split(":", 1) for l in basic)
)

# 2. PhoneInfoga (group links by heading)
groups, current = {}, "General"
for line in read("phoneinfoga.txt").splitlines():
    s = line.strip()
    if s.startswith("URL:"):
        groups.setdefault(current, []).append(s[4:].strip())
    elif s.endswith(":") and not line.startswith((" ", "\t")):
        current = s[:-1]
pi_html = ""
for g, links in groups.items():
    items = "".join(
        f'<li><a href="{esc(u)}" target="_blank" rel="noopener">{esc(u.split("q=")[-1][:90])}</a></li>'
        for u in links
    )
    pi_html += f"<h3>{esc(g)} ({len(links)})</h3><ul>{items}</ul>"

# 3. Ignorant
ign_html = ""
for l in read("ignorant.txt").splitlines():
    s = l.strip()
    if s[:3] in ("[+]", "[-]", "[x]"):
        cls = {"[+]": "found", "[-]": "no", "[x]": "limit"}[s[:3]]
        label = {"[+]": "Registered", "[-]": "Not registered", "[x]": "Rate limited"}[s[:3]]
        ign_html += f'<tr><td>{esc(s[3:].strip())}</td><td class="{cls}">{label}</td></tr>'

# 4. Dorks
dorks = [l for l in read("dorks.txt").splitlines() if l.strip()]
dork_html = "".join(
    f'<li><a href="https://www.google.com/search?q={esc(__import__("urllib.parse").parse.quote(d))}" '
    f'target="_blank" rel="noopener">{esc(d)}</a></li>' for d in dorks
)

page = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Phone OSINT Lab Report</title>
<style>
body{{font-family:system-ui,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem;background:#111;color:#ddd}}
h1,h2,h3{{color:#6cf}} a{{color:#8cf;word-break:break-all}}
table{{border-collapse:collapse;width:100%;margin-bottom:1rem}}
th,td{{border:1px solid #333;padding:6px 10px;text-align:left}} th{{width:30%;background:#1b1b1b}}
.found{{color:#4f4}} .no{{color:#aaa}} .limit{{color:#fb4}}
.note{{background:#222;border-left:4px solid #fb4;padding:8px 12px}}
</style></head><body>
<h1>Phone OSINT Lab Report</h1>
<p>Folder: {esc(out.name)}<br>Generated: {datetime.datetime.now():%Y-%m-%d %H:%M}</p>
<p class="note">Educational use only. Test only your own number or numbers with written consent.
This report shows public metadata, not a person's identity.</p>
<h2>1. Number details</h2><table>{basic_rows}</table>
<h2>2. PhoneInfoga search links</h2>{pi_html}
<h2>3. Site registration check (Ignorant)</h2>
<table><tr><th>Site</th><th>Status</th></tr>{ign_html}</table>
<h2>4. Manual Google dorks</h2><ul>{dork_html}</ul>
</body></html>"""

(out / "report.html").write_text(page)
print(f"Report saved: {out / 'report.html'}")
