#!/usr/bin/env python3
"""Usage: make_generic_report.py <output_folder>"""
import sys, html, pathlib, re, datetime

out = pathlib.Path(sys.argv[1])
ansi = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')

def linkify(t):
    return re.sub(r'(https?://[^\s<]+)',
                  r'<a href="\1" target="_blank" rel="noopener">\1</a>', t)

sections = ""
for f in sorted(out.glob("*.txt")):
    text = ansi.sub("", f.read_text(errors="replace"))
    sections += f"<h2>{html.escape(f.stem)}</h2><pre>{linkify(html.escape(text))}</pre>"

page = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<title>OSINT Lab Report</title><style>
body{{font-family:system-ui,sans-serif;max-width:950px;margin:2rem auto;padding:0 1rem;background:#111;color:#ddd}}
h1,h2{{color:#6cf}} a{{color:#8cf}} pre{{background:#1b1b1b;padding:10px;overflow-x:auto;white-space:pre-wrap;word-break:break-word}}
.note{{background:#222;border-left:4px solid #fb4;padding:8px 12px}}
</style></head><body>
<h1>OSINT Lab Report</h1>
<p>Folder: {html.escape(out.name)}<br>Generated: {datetime.datetime.now():%Y-%m-%d %H:%M}</p>
<p class="note">Educational use only. Own data or written consent only.</p>
{sections}</body></html>"""

(out / "report.html").write_text(page)
print(f"Report saved: {out/'report.html'}")
