from PIL import Image
im=Image.open('assets/art_direction/fridge-doors-source.png').convert('RGBA')
print(im.size)
# Individual sprite bounds, with a shared hinge and scale; keep the swing projection.
bands=[(30,630),(655,1175),(1240,1635),(1780,2005)]
out=Image.new('RGBA',(416,64))
for i,(x0,x1) in enumerate(bands):
 c=im.crop((x0,150,x1,610)); b=c.getbbox(); c=c.crop((b[0],0,c.width,460))
 c=c.resize((round(c.width*0.175),56),Image.Resampling.LANCZOS)
 out.alpha_composite(c,(i*104+1,0))
out.save('assets/fridge-doors.png')
