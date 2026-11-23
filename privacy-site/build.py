from pathlib import Path
import re

root = Path(__file__).resolve().parent
source = (root.parent / 'backend/resources/views/legal.blade.php').read_text(encoding='utf-8')
privacy = source.split("@if ($page === 'privacy')", 1)[1].split('@elseif', 1)[0]
terms = source.split("@elseif ($page === 'terms')", 1)[1].split('@else', 1)[0]
deletion = source.split('@else\n', 1)[1].split('@endif', 1)[0]
css = '''
:root{color-scheme:light;--ink:#202b33;--muted:#617078;--line:#dce1df;--accent:#255c4c}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:30px}
body{margin:0;background:#fafbf9;color:var(--ink);font:16px/1.8 Arial,sans-serif}
a{color:var(--accent);text-underline-offset:4px}a:hover{text-decoration-thickness:2px}
.header{border-bottom:1px solid var(--line);background:#fff}.bar{max-width:1160px;margin:auto;padding:23px 32px;display:flex;align-items:center;justify-content:space-between;gap:24px}
.brand{font-weight:700;font-size:20px;letter-spacing:-.6px;text-decoration:none;color:var(--ink)}nav{display:flex;gap:24px;flex-wrap:wrap}nav a{font-size:14px;text-decoration:none}nav a[aria-current=page]{text-decoration:underline}
.layout{max-width:1160px;margin:auto;display:grid;grid-template-columns:220px minmax(0,760px);gap:64px;padding:62px 32px 90px}
aside{font-size:13px}aside p{font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--muted)}aside a{display:block;text-decoration:none;padding:5px 0;line-height:1.5}
.eyebrow{font-size:12px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--accent);margin:0 0 12px}h1{font:normal 48px/1.15 Georgia,serif;letter-spacing:-1.3px;margin:0 0 18px}.meta{font-size:13px;color:var(--muted);border-bottom:1px solid var(--line);padding-bottom:30px;margin-bottom:30px}
h2{font:normal 26px/1.3 Georgia,serif;margin:42px 0 14px}p{margin:0 0 18px}li{padding-left:3px;margin:9px 0}ul,ol{padding-left:23px}.box{padding:20px 24px;border-left:3px solid var(--accent);background:#f0f4f0;margin:24px 0}.box h2{margin-top:0!important}
footer{border-top:1px solid var(--line);max-width:1096px;margin:auto;padding:26px 0;color:var(--muted);font-size:13px;display:flex;justify-content:space-between;gap:20px}
@media(max-width:800px){.bar{align-items:flex-start;flex-direction:column;padding:20px 24px}nav{gap:18px}.layout{display:block;padding:36px 24px 60px}aside{display:none}h1{font-size:38px}footer{margin:0 24px;flex-direction:column}.meta{padding-bottom:24px}}
@media print{aside,.header,footer{display:none}.layout{display:block;padding:0}body{background:white;font-size:11pt}h1{font-size:30pt}h2{break-after:avoid}}
'''
(root/'dist/styles.css').write_text(css,encoding='utf-8')
pages = [('privacy-policy','Privacy policy',privacy),('terms','Terms of use',terms),('account-deletion','Delete your Edu Connect account',deletion)]
for slug,title,body in pages:
    headings=[]
    def heading(match):
        text=match.group(1)
        anchor=re.sub('[^a-z0-9]+','-',re.sub('<[^>]+>','',text).lower()).strip('-')
        headings.append((anchor,text))
        return f'<h2 id="{anchor}">{text}</h2>'
    body=re.sub(r'<h2>(.*?)</h2>',heading,body)
    navigation=''.join(f'<a href="/{s}"'+(' aria-current="page"' if s==slug else '')+f'>{"Account deletion" if s=="account-deletion" else t}</a>' for s,t,_ in pages)
    contents=''.join(f'<a href="#{a}">{t}</a>' for a,t in headings)
    html=f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="description" content="Edu Connect {title.lower()}: information about your data, your choices and how to contact support."><title>{title} | Edu Connect</title><link rel="stylesheet" href="/styles.css"><link rel="canonical" href="https://codedevs.chewetechnologies.co.zw/{slug}"></head>
<body><header class="header"><div class="bar"><a class="brand" href="/">Edu Connect</a><nav aria-label="Legal documents">{navigation}</nav></div></header><div class="layout"><aside aria-label="On this page"><p>On this page</p>{contents}</aside><main id="content"><p class="eyebrow">Privacy and your data</p><h1>{title}</h1><p class="meta">Edu Connect &nbsp; / &nbsp; Last updated 30 October 2026</p>{body}</main></div><footer><span>Edu Connect · School and home, connected.</span><a href="mailto:admin@teramark.co.zw">admin@teramark.co.zw</a></footer></body></html>'''
    (root/'dist'/f'{slug}.html').write_text(html,encoding='utf-8')
    if slug=='privacy-policy': (root/'dist/index.html').write_text(html,encoding='utf-8')
print('Built privacy policy, terms and account deletion pages.')
