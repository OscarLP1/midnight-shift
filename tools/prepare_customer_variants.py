"""Normalize generated directions to the protagonist's 32x48 cells and feet y=44."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
for name in ('woman', 'senior', 'courier'):
    source = Image.open(ROOT / f'assets/art_direction/{name}-source.png').convert('RGBA')
    cells = []
    for row in range(4):
        for col in range(4):
            cell = source.crop((col*source.width//4,row*source.height//4,(col+1)*source.width//4,(row+1)*source.height//4))
            # Discard generated low-alpha halos; keep the opaque pixel-art silhouette.
            cell.putalpha(cell.getchannel('A').point(lambda a: 255 if a>=240 else 0))
            box = cell.getbbox()
            assert box is not None
            cells.append(cell.crop(box))
    scale = min(28/max(c.width for c in cells),42/max(c.height for c in cells))
    sheet = Image.new('RGBA',(128,192))
    for i,cell in enumerate(cells):
        cell = cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        sheet.alpha_composite(cell,((i%4)*32+(32-cell.width)//2,(i//4)*48+44-cell.height))
    for row in range(4):
        for col in range(4):
            cell = sheet.crop((col*32,row*48,col*32+32,row*48+48))
            bounds = cell.getbbox()
            assert bounds and bounds[3]==44 and bounds[0]>0 and bounds[2]<32
    sheet.save(ROOT / f'assets/customer-{name}.png')
    print(name, '16 frames verified; transparent RGBA 128x192; baseline 44')
