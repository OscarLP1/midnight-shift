"""Normalize the 8-phase walk/run sheets without replacing original wardrobe heads."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ("employee-walk-8", "employee-run-8", "police-run-8", "burglar-run-8")
for name in NAMES:
    source = Image.open(ROOT / f"assets/art_direction/{name}-source.png").convert("RGBA")
    cells = []
    for row in range(4):
        for col in range(8):
            cell = source.crop((col*source.width//8,row*source.height//4,
                                (col+1)*source.width//8,(row+1)*source.height//4))
            cell.putalpha(cell.getchannel("A").point(lambda a:255 if a>=240 else 0))
            assert cell.getbbox(), (name,row,col)
            cells.append(cell.crop(cell.getbbox()))
    scale = min(28/max(c.width for c in cells),40/max(c.height for c in cells))
    sheet = Image.new("RGBA",(256,192))
    for i, cell in enumerate(cells):
        cell = cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        cell = cell.crop(cell.getbbox())
        sheet.alpha_composite(cell,((i%8)*32+(32-cell.width)//2,(i//8)*48+44-cell.height))
    counts = []
    for row in range(4):
        frames = [sheet.crop((c*32,row*48,(c+1)*32,(row+1)*48)) for c in range(8)]
        counts.append(len({f.tobytes() for f in frames}))
        assert all(f.getbbox()[3]==44 for f in frames)
        assert counts[-1]>=6, (name,row,"too few distinct poses")
    sheet.save(ROOT / f"assets/{name}.png")
    previews = []
    for col in range(8):
        canvas = Image.new("RGB",(384,160),"#25323c")
        for row in range(4):
            frame = sheet.crop((col*32,row*48,(col+1)*32,(row+1)*48)).resize((96,144),Image.Resampling.NEAREST)
            canvas.paste(frame,(row*96,8),frame)
        previews.append(canvas)
    previews[0].save(ROOT / f"docs/{name}.gif",save_all=True,append_images=previews[1:],duration=90,loop=0)
    print(name,"distinct poses per direction:",counts)
