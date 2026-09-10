#!/usr/bin/env python3
"""Build the static eight-colour title picture as a CHIP AmigaDOS executable."""
import hashlib
from pathlib import Path
import shutil
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[2]
WIDTH,HEIGHT,DEPTH=640,512,3
SOURCE=ROOT/'src/intro/assets/picture.bin'
# Preserve the artwork's black, white, grey, gold, greens and sea blues.
PALETTE=[(0,0,0),(238,238,238),(136,136,136),(179,138,34),
         (30,68,32),(94,145,43),(6,54,164),(20,100,189)]


def build(work=None):
    work=Path(work or ROOT/'work/intro').resolve()
    work.mkdir(parents=True,exist_ok=True)
    planes=SOURCE.read_bytes()
    rowbytes=WIDTH//8
    if len(planes) != rowbytes*HEIGHT*DEPTH:
        raise ValueError('Unexpected planar picture size')
    (work/'picture.bin').write_bytes(planes)
    palette=[component for colour in PALETTE for component in colour]
    generated=work/'picture.i'
    lines=[f'IMAGE_WIDTH equ {WIDTH}',f'IMAGE_HEIGHT equ {HEIGHT}',
           f'IMAGE_DEPTH equ {DEPTH}',f'IMAGE_ROW_BYTES equ {rowbytes}',
           'image_palette:',f' dc.l ${(1<<DEPTH)<<16:08x}']
    for i in range(0,len(palette),3):
        lines.append(' dc.l '+','.join(f'${c*0x01010101:08x}' for c in palette[i:i+3]))
    lines+=[' dc.l 0','image_data:',f' incbin "{work / "picture.bin"}"']
    generated.write_text('\n'.join(lines)+'\n')
    wrapper=work/'intro.s'
    wrapper.write_text(f' include "src/intro/intro.s"\n include "{generated}"\n')
    assembler=shutil.which('vasmm68k_mot')
    if not assembler:raise RuntimeError('vasmm68k_mot missing')
    output=work/'intro.bin'
    assembled=subprocess.run([assembler,'-m68060','-Fbin','-L',str(work/'intro.lst'),'-o',str(output),str(wrapper)],
                             cwd=ROOT,capture_output=True,text=True)
    if assembled.returncode:
        raise RuntimeError(assembled.stdout+assembled.stderr)
    data=output.read_bytes()
    padded=data+bytes((-len(data))%4)
    words=len(padded)//4
    header=struct.pack('>8I',1011,0,1,0,0,0x40000000|words,1001,words)
    (work/'HunterIntro').write_bytes(header+padded+struct.pack('>I',1010))
    return data


if __name__=='__main__':
    data=build()
    print('Intro:',len(data),'bytes',hashlib.sha256(data).hexdigest())
