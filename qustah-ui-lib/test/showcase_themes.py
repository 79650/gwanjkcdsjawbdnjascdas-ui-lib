# Theme grid for the README: test/showcase/theme_*.png -> one image with labels.
import sys
from PIL import Image, ImageDraw, ImageFont
d=sys.argv[1]; out=sys.argv[2]
names=[("dark","Dark"),("light","Light"),("tokyonight","Tokyo Night"),("cyberpunk","Cyberpunk"),("gruvbox","Gruvbox"),("mint","Mint")]
W=780; gx=40; gy=24; lab=70; cols=3
ims=[Image.open(f"{d}/theme_{n}.png").convert("RGBA") for n,_ in names]
ims=[im.resize((W, round(im.height*W/im.width)), Image.LANCZOS) for im in ims]
H=max(i.height for i in ims)
rows=(len(ims)+cols-1)//cols
canvas=Image.new("RGBA",(cols*W+(cols-1)*gx, rows*(H+lab)+(rows-1)*gy),(0,0,0,0))
font=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-SemiBold.otf",28)
dr=ImageDraw.Draw(canvas)
for k,(im,(n,label)) in enumerate(zip(ims,names)):
    x=(k%cols)*(W+gx); y=(k//cols)*(H+lab+gy)
    canvas.alpha_composite(im,(x,y))
    tw=dr.textlength(label,font=font)
    dr.text((x+(W-tw)/2, y+H+16), label, font=font, fill=(138,138,146,255))
canvas.save(out, optimize=True); print(canvas.size)
