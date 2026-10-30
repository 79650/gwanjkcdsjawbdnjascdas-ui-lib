# Tab-switching GIF for the README: crossfades between the showcase shots.
import sys
from PIL import Image
d=sys.argv[1]; out=sys.argv[2]
order=["dashboard","visuals","combat","player","live","inputs","buttons","settings"]
W=960; PAD=0; BG=(10,10,11)
def load(n):
    im=Image.open(f"{d}/{n}.png").convert("RGBA")
    im=im.resize((W, round(im.height*W/im.width)), Image.LANCZOS)
    bg=Image.new("RGBA",im.size,BG+(255,)); bg.alpha_composite(im); return bg.convert("RGB")
ims=[load(n) for n in order]
H=max(i.height for i in ims); ims=[i if i.height==H else i.resize((W,H)) for i in ims]
frames=[]; durs=[]
FADE=4
for k,im in enumerate(ims):
    frames.append(im); durs.append(1700)
    nxt=ims[(k+1)%len(ims)]
    for f in range(1,FADE+1):
        frames.append(Image.blend(im,nxt,f/(FADE+1))); durs.append(45)
pal=[f.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) for f in frames]
pal[0].save(out, save_all=True, append_images=pal[1:], duration=durs, loop=0, optimize=True, disposal=1)
print(len(frames), W, H)
