import pathlib,urllib.parse,urllib.request,re
root=pathlib.Path(__file__).resolve().parents[1]
text=''.join(p.read_text() for p in (root/'scripts').glob('*.gd'))
text+=''.join(chr(i) for i in range(32,127))+'− / + 0123456789%'
chars=''.join(sorted(set(text)))
url='https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400&text='+urllib.parse.quote(chars)
css=urllib.request.urlopen(url,timeout=30).read().decode()
fonturl=re.search(r'url\((.*?)\)',css).group(1)
data=urllib.request.urlopen(fonturl,timeout=30).read()
assert data[:4] in (b'\x00\x01\x00\x00',b'OTTO',b'wOF2')
(root/'assets/fonts/GameFont.ttf').write_bytes(data)
(root/'source_assets/font-source.txt').write_text('Noto Sans SC, weight 400, Google Fonts text subset. SIL OFL 1.1.\n'+url+'\n'+fonturl+'\n')
print('Font subset:',len(data),'bytes')
