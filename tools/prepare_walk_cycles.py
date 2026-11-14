"""Prepare real 4x4 walk cycles with uniform scale and a stable foot baseline."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPECS = {"police-officer": (32,48,28,40,44),
         **{f"monster-walk-{i}": (40,64,36,56,60) for i in range(3)},
         **{f"customer-{name}": (32,48,28,40,44) for name in ("woman","senior","courier")},
         "stray-dog": (32,48,29,25,44)}

for name, (cw,ch,mw,mh,baseline) in SPECS.items():
    path = ROOT / f"assets/art_direction/{name}-walk-source.png"
    if not path.exists():
        continue
    source = Image.open(path).convert("RGBA")
    cells = []
    for row in range(4):
        for col in range(4):
            cell = source.crop((col*source.width//4,row*source.height//4,
                                (col+1)*source.width//4,(row+1)*source.height//4))
            cell.putalpha(cell.getchannel("A").point(lambda a:255 if a>=240 else 0))
            assert cell.getbbox(), (name,row,col)
            cells.append(cell.crop(cell.getbbox()))
    scale = min(mw/max(c.width for c in cells), mh/max(c.height for c in cells))
    sheet = Image.new("RGBA",(cw*4,ch*4))
    for i, cell in enumerate(cells):
        cell = cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        cell = cell.crop(cell.getbbox())
        sheet.alpha_composite(cell,((i%4)*cw+(cw-cell.width)//2,(i//4)*ch+baseline-cell.height))
    for row in range(4):
        frames = [sheet.crop((c*cw,row*ch,(c+1)*cw,(row+1)*ch)) for c in range(4)]
        assert len({f.tobytes() for f in frames})==4, (name,row,"repeated frames")
        assert all(f.getbbox()[3]==baseline for f in frames)
    sheet.save(ROOT / f"assets/{name}.png")
    preview = []
    for frame in range(4):
        canvas = Image.new("RGB",(cw*4*3,ch*3+12),"#25323c")
        for direction in range(4):
            cell = sheet.crop((frame*cw,direction*ch,(frame+1)*cw,(direction+1)*ch))
            cell = cell.resize((cw*3,ch*3),Image.Resampling.NEAREST)
            canvas.paste(cell,(direction*cw*3,6),cell)
        preview.append(canvas)
    preview[0].save(ROOT / f"docs/{name}-walk.gif",save_all=True,append_images=preview[1:],duration=150,loop=0)
    print(name,"16 distinct frames; four directions; stable baseline")
