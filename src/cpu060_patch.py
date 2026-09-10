"""Assemble the Hunter 68060 runtime and apply its executable hooks."""
from pathlib import Path
import re
import subprocess
import struct

ROOT = Path(__file__).resolve().parents[1]


def word(value):
    return struct.pack('>H', value & 0xffff)


def branch(source, target, opcode=0x6000):
    delta = target - (source + 2)
    if not -32768 <= delta <= 32767:
        raise ValueError('Branch displacement out of range')
    return word(opcode) + word(delta)


def patch_cpu060(exe, output, unpack, fast_data=True, terrain_delta=True, terrain_div=True, terrain_project=True, span_fill=True, trapezoid_fill=True, view_9=True):
    if view_9 and not fast_data:
        raise ValueError("View 9 requires fast data")
    game = unpack(exe[0x92e8:])
    records = []
    if trapezoid_fill:
        for index, start, end in ((2, 0x7ec8, 0x7ef8), (3, 0x7ef8, 0x7f28)):
            body = game[start-0x700:end-0x700]
            if body[-2:] != bytes.fromhex('4e75'):
                raise ValueError('Unexpected trapezoid operation return')
            (output/f'trapezoid_fill_{index}.bin').write_bytes(body[:-2])
    if span_fill:
        # Every original operation is self-contained and ends in one RTS.
        targets = [0x7e6c,0x7e98,0x7ec8,0x7ef8,0x7f28,0x7f56,0x7f7c,
                   0x7fa6,0x7fd0,0x7ff8,0x8018,0x803c,0x805e,0x8078,0x8094]
        target_lines, loop_lines = [], []
        target_indexes = {address: index for index, address in enumerate(targets[:-1])}
        # Index by the original target's even byte offset. Holes remain zero
        # so unknown selectors take the unchanged fallback loop.
        for address in range(targets[0], targets[-2] + 2, 2):
            index = target_indexes.get(address)
            entry = '0' if index is None else f'Span_Loop_{index}-Resident_SpanFill'
            target_lines.append(f'        dc.w {entry}')
        for index,(start,end) in enumerate(zip(targets,targets[1:])):
            body = game[start-0x700:end-0x700]
            if body[-2:] != bytes.fromhex('4e75') or body.count(bytes.fromhex('4e75')) != 1:
                raise ValueError(f'Unexpected scanline operation at {start:#x}')
            name = f'span_fill_{index}.bin'
            (output/name).write_bytes(body[:-2])
            loop_lines.append(f'        span_loop "{name}",{index}')
        (output/'span_fill_targets.i').write_text('\n'.join(target_lines)+'\n')
        (output/'span_fill_loops.i').write_text('\n'.join(loop_lines)+'\n')

    def replace(address, expected, replacement):
        offset = address - 0x700
        if game[offset:offset + len(expected)] != expected:
            raise ValueError(f'Unexpected game bytes at {address:#x}')
        if len(expected) != len(replacement):
            raise ValueError('In-place game patch size mismatch')
        records.append((address, replacement))

    # Retain one selector table, now storing absolute low words. The second
    # table becomes a register-preserving indirect tail-call trampoline.
    for address, target in ((0x7964, 0x7e6c), (0x7c80, 0x7ef8)):
        replace(address, branch(address, target, 0x6100), branch(address, 0x7d2c, 0x6100))
    first = game[0x7cec-0x700:0x7d2c-0x700]
    targets = [int.from_bytes(first[i:i+2], 'big') for i in range(0,64,2)]
    table = b''.join(word(value + 0x7966) if i % 8 < 5 else word(0)
                     for i, value in enumerate(targets))
    replace(0x7cec, first, table)
    old = game[0x7d2c-0x700:0x7d6c-0x700]
    trampoline = bytes.fromhex('4ef900000000') + bytes(50) if fast_data else bytes(56)
    if terrain_delta:
        trampoline = trampoline[:6] + bytes.fromhex('4ef900000000') + trampoline[12:]
    if terrain_project:
        trampoline = trampoline[:12] + bytes.fromhex('4ef900000000') + trampoline[18:]
    replace(0x7d2c, old, bytes.fromhex('2f3900007c984e75') + trampoline)
    if terrain_delta:
        # EXT/BEQ/DIVS on the far edge; keep the near zero-delta bypass.
        replace(0x3b52, bytes.fromhex('4882670281c2'), bytes.fromhex('4eb900000000'))
        replace(0x3c1c, bytes.fromhex('200381c2'), branch(0x3c1c, 0x7d3a, 0x6100))
    if terrain_div:
        for address in (0x3714, 0x3732, 0x373e):
            replace(address, bytes.fromhex('83fc0100e841'), bytes.fromhex('4eb900000000'))
    if terrain_project:
        for address in (0x3b72, 0x3bc4):
            replace(address, bytes.fromhex('81c283c2'), branch(address, 0x7d40, 0x6100))
    if span_fill:
        replace(0x7918, bytes.fromhex('49fa00544246'), bytes.fromhex('4ef900000000'))
    if trapezoid_fill:
        replace(0x7c00, bytes.fromhex('4cba0f00008c'), bytes.fromhex('4ef900000000'))
    if fast_data:
        replace(0x1efe, branch(0x1efe, 0x83c4, 0x6100), branch(0x1efe, 0x7d34, 0x6100))
    replace(0x7c98, bytes(4), bytes.fromhex('00007e6c'))
    old = game[0x7cbe-0x700:0x7cc6-0x700]
    if old[-4:] != bytes.fromhex('00007966'):
        raise ValueError('Unexpected SMC writer')
    replace(0x7cbe, old, old[:4] + bytes.fromhex('00007c9a'))
    old = game[0x7cc6-0x700:0x7cce-0x700]
    if old[-4:] != bytes.fromhex('00007c82'):
        raise ValueError('Unexpected second SMC writer')
    replace(0x7cc6, old, bytes.fromhex('4e71') * 4)
    if game[0x1eba-0x700:0x1ec0-0x700] != bytes.fromhex('4ff90007e800'):
        raise ValueError('Unexpected supervisor stack setup')
    include = output / 'game_patches.i'
    include.write_text(''.join(
        f'        dc.l ${address+0x40000:X}\n        dc.w {len(data)-1}\n'
        + '        dc.b ' + ','.join(f'${b:02X}' for b in data) + '\n'
        for address, data in records))
    # Install these only after successful allocation, preserving a 7x7 fallback.
    view_records = []
    if view_9:
        for address, expected, replacement in (
            (0x3792, '00001c00', '00002400'),
            (0x37cc, '0007', '0009'),
            (0x4218, '1800', '2000'),
            (0x39b0, '6100016a6100', '4ef900000000'),
            (0x3b1c, '61b643fafcf0', '4ef900000000'),
            (0x4230, 'd46d154c48c2', '4ef900000000'),
            (0x4e66, '43fafea63b7c', '4ef900000000'),
        ):
            expected, replacement = bytes.fromhex(expected), bytes.fromhex(replacement)
            if game[address-0x700:address-0x700+len(expected)] != expected:
                raise ValueError(f'Unexpected view patch bytes at {address:#x}')
            view_records.append((address, replacement))
    (output / 'view9_patches.i').write_text(''.join(
        f'        dc.l ${address+0x40000:X}\n        dc.w {len(data)-1}\n'
        + '        dc.b ' + ','.join(f'${b:02X}' for b in data) + '\n'
        for address, data in view_records))
    binary, listing = output / 'cpu060.bin', output / 'cpu060.lst'
    subprocess.run(['vasmm68k_mot', '-Fbin', f'-DFAST_DATA={int(fast_data)}',
                    f'-DTERRAIN_DELTA={int(terrain_delta)}', f'-DTERRAIN_DIV={int(terrain_div)}',
                    f'-DTERRAIN_PROJECT={int(terrain_project)}', f'-DSPAN_FILL={int(span_fill)}', f'-DTRAPEZOID_FILL={int(trapezoid_fill)}', f'-DVIEW_9={int(view_9)}', '-I'+str(output), '-I'+str(ROOT / 'src'), '-L', str(listing),
                    '-o', str(binary), str(ROOT / 'src/cpu060.s')], check=True,
                   stdout=subprocess.PIPE, text=True)
    symbols = {m[2]: int(m[1],16) for line in listing.read_text().splitlines()
               if (m := re.fullmatch(r'([0-9A-Fa-f]{8}) ([A-Za-z_][A-Za-z0-9_]*)',line))}
    payload = binary.read_bytes()
    if symbols['Resident_End'] - symbols['Resident_Start'] > 0x1000:
        raise ValueError('Resident code overlaps loader directory buffer')
    if view_9 and symbols['View9_End'] - symbols['View9_Start'] > 0x1000:
        raise ValueError('View module exceeds its Fast arena extension')
    result = bytearray(exe[:0xee8] + payload + exe[0xee8:])

    def file_patch(offset, expected, new):
        if result[offset:offset+len(expected)] != expected or len(expected) != len(new):
            raise ValueError(f'Unexpected bootstrap/loader bytes at {offset:#x}')
        result[offset:offset+len(new)] = new

    for offset in (0x14,0x20):
        file_patch(offset, (0x3b1).to_bytes(4,'big'), (0x3b1+len(payload)//4).to_bytes(4,'big'))
    file_patch(0x4a, bytes.fromhex('4eaefdd8'), branch(0x4a,symbols['Bootstrap_OpenDos'],0x6100))
    file_patch(0x24a,bytes.fromhex('4ef900040700'),branch(0x24a,symbols['Bootstrap_Install'])+bytes.fromhex('4e71'))
    # The only stream seek immediate moves with the extended HUNK.
    if result[0x110:0x116] != bytes.fromhex('243c00000ef8'):
        raise ValueError('Unexpected overlay seek')
    result[0x112:0x116] = (0xef8+len(payload)).to_bytes(4,'big')
    # MOVEP is absent on 68060. Its word is only used for the optional border
    # flash, so remove the entire flash; D4 is saved by PP20_Decrunch.
    file_patch(0x492+0x150, bytes.fromhex('090800013d4401803d7c00000180'),
               bytes.fromhex('4e71')*7)
    resident_return = 0xd98 + symbols['Resident_LoaderReturn'] - symbols['Resident_Start']
    file_patch(0x222+0x150,bytes.fromhex('4cdf7fff'),branch(0x222,resident_return))
    if result[0xee8+len(payload):] != exe[0xee8:]:
        raise ValueError('Original intro/game streams changed')
    return bytes(result), dict(view_9=view_9, view_patch_records=len(view_records), view_module_bytes=symbols['View9_End']-symbols['View9_Start'] if view_9 else 0,
                              trapezoid_fill=trapezoid_fill, span_fill=span_fill, terrain_project=terrain_project, terrain_div=terrain_div, terrain_delta=terrain_delta, terrain_delta_bytes=512 if terrain_delta else 0,
                              fast_data=fast_data, fast_data_bytes=(0x18a00 + 0x1000*view_9) if fast_data else 0,
                              payload_bytes=len(payload),game_patches=len(records),
                              resident_bytes=symbols['Resident_End']-symbols['Resident_Start'],
                              symbols=symbols)
