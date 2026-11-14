from PIL import Image
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'assets'
source = Image.open(root/'art_direction/store-production-source.png').convert('RGBA')
source.resize((640,360),Image.Resampling.NEAREST).save(root/'store-modern.png')
source = Image.open(root/'art_direction/employee-production-source.png').convert('RGBA')
sheet = Image.new('RGBA',(128,192))
for row in range(4):
    for col in range(4):
        cell = source.crop((col*source.width//4,row*source.height//4,(col+1)*source.width//4,(row+1)*source.height//4))
        bounds = cell.getchannel('A').point(lambda a: 255 if a>100 else 0).getbbox()
        assert bounds, (row,col)
        cell=cell.crop(bounds)
        scale=min(28/cell.width,42/cell.height)
        cell=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
        sheet.alpha_composite(cell,(col*32+(32-cell.width)//2,row*48+44-cell.height))
sheet.save(root/'employee-modern.png')
# Same body proportions for the first customer, rust jacket and no teal uniform.
customer=sheet.copy()
pixels=customer.load()
for y in range(customer.height):
    for x in range(customer.width):
        r,g,b,a=pixels[x,y]
        if a and g>r*1.18 and b>r*1.12:
            pixels[x,y]=(min(255,int(g*1.2)),int(g*.70),int(b*.58),a)
customer.save(root/'customer-modern.png')
print('Three production PNGs prepared; 16 aligned frames per character.')
