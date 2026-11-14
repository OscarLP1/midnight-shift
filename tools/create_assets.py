from PIL import Image, ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets'
ROOT.mkdir(exist_ok=True)
for name,shirt in [('employee','#54b9b0'),('customer','#c88b66')]:
    im=Image.new('RGBA',(128,192))
    d=ImageDraw.Draw(im)
    for direction in range(4):
        for frame in range(4):
            x=frame*32;y=direction*48; bob=frame%2
            d.ellipse((x+6,y+40,x+26,y+45),fill='#131c32aa')
            d.rectangle((x+10,y+28+bob,x+14,y+40+(frame%2)*2),fill='#29344c')
            d.rectangle((x+18,y+28+bob,x+22,y+42-(frame%2)*2),fill='#29344c')
            d.rectangle((x+8,y+17+bob,x+24,y+30+bob),fill=shirt)
            d.rectangle((x+8,y+27+bob,x+24,y+29+bob),fill='#477a85')
            d.rectangle((x+6,y+20+bob,x+9,y+30+bob),fill='#d99f7f')
            d.rectangle((x+24,y+20+bob,x+27,y+30+bob),fill='#d99f7f')
            d.rectangle((x+10,y+5+bob,x+22,y+17+bob),fill='#e6b18d')
            d.rectangle((x+9,y+3+bob,x+23,y+9+bob),fill='#332d40')
            if direction==1:d.rectangle((x+10,y+8+bob,x+22,y+15+bob),fill='#332d40')
            else:
                eyes=[13,20] if direction==0 else ([11] if direction==2 else [21])
                for e in eyes:d.point((x+e,y+12+bob),fill='#172239')
            if name=='employee' and direction!=1:d.rectangle((x+18,y+20+bob,x+21,y+22+bob),fill='#ffdf9e')
    im.save(ROOT/(name+'.png'))
im=Image.new('RGBA',(640,360),'#111c31');d=ImageDraw.Draw(im)
d.rectangle((24,43,616,305),fill='#37394b')
for y in range(64,304,16):
 for x in range(32,608,16):
  d.rectangle((x,y,x+14,y+14),fill=('#77736a' if (x+y)%32 else '#827c70'))
  d.line((x,y,x+14,y),fill='#969080')
d.rectangle((24,40,616,63),fill='#474356');d.line((24,62,616,62),fill='#d0ac77',width=3)
for x in range(48,550,90):
 d.rectangle((x,44,x+65,57),fill='#172b42');d.line((x+3,45,x+60,45),fill='#64bcbf')
for x in [160,320,480]:
 d.rectangle((x,120,x+62,173),fill='#282b3b')
 for row in range(3):
  yy=123+row*15
  for i in range(7):
   c=['#d99170','#b7bf82','#7aafb6','#c6a0b9'][i%4]
   d.rectangle((x+4+i*8,yy,x+9+i*8,yy+10),fill=c)
   d.line((x+5+i*8,yy+4,x+8+i*8,yy+4),fill='#f4dca6')
  d.line((x,yy+12,x+62,yy+12),fill='#ae936f',width=2)
d.rectangle((76,220,145,254),fill='#34364b');d.rectangle((74,217,147,229),fill='#b09170')
d.rectangle((96,203,119,219),fill='#20293c');d.rectangle((99,206,116,215),fill='#7bc5bc')
d.rectangle((276,302,365,308),fill='#a1886c')
for y in range(318,360,15):d.line((0,y,640,y),fill='#253348')
for x in range(0,640,34):d.line((x,320,x+7,335),fill='#415c72')
im.save(ROOT/'store.png')
print('Created store.png, employee.png, customer.png')
