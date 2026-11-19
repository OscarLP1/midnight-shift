from pathlib import Path
from PIL import Image
root=Path('.')
src=Image.open('assets/art_direction/professional-customers-source.png').convert('RGBA')
bands=[(20,188),(188,360),(360,520),(520,688),(688,844),(844,1000),(1000,1150),(1150,1304),(1304,1466),(1466,1620),(1620,1752),(1752,1881)]
for n,name in enumerate(['doctor','pilot','mechanic']):
 cells=[]
 for y0,y1 in bands[n*4:n*4+4]:
  for col in range(4):
   c=src.crop((col*209,y0,(col+1)*209,y1)); c.putalpha(c.getchannel('A').point(lambda a:255 if a>=240 else 0)); cells.append(c.crop(c.getbbox()))
 scale=min(28/max(c.width for c in cells),40/max(c.height for c in cells))
 out=Image.new('RGBA',(128,192))
 for i,c in enumerate(cells):
  c=c.resize((round(c.width*scale),round(c.height*scale)),Image.Resampling.NEAREST)
  out.alpha_composite(c,((i%4)*32+(32-c.width)//2,(i//4)*48+44-c.height))
 out.save(f'assets/customer-{name}.png')
print('Rebuilt 48 complete frames from actual row boundaries')
