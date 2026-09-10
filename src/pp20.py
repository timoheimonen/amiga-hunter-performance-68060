"""Decode the original game stream for patch source assembly."""

def unpack_pp20(data):
    """Decompress PP20 using the reference loader.s semantics with bounds checks."""
    if data[:4] != b"PP20" or len(data) < 12:
        raise ValueError("Missing PP20 header")
    size = int.from_bytes(data[-4:-1], "big")
    if not 0 < size <= 0x1000000 or data[-1] > 31:
        raise ValueError("Invalid PP20 trailer")
    bit_pos = data[-1]
    payload = data[8:-4]

    def bits(n):
        nonlocal bit_pos
        result = 0
        for _ in range(n):
            if bit_pos >= len(payload) * 8:
                raise ValueError("PP20 input exhausted")
            byte = payload[-1 - bit_pos // 8]
            result = (result << 1) | ((byte >> (bit_pos % 8)) & 1)
            bit_pos += 1
        return result

    out = bytearray(size)
    cursor = size
    while cursor:
        if bits(1) == 0:
            length = 1
            while True:
                part = bits(2)
                length += part
                if part != 3:
                    break
            if length > cursor:
                raise ValueError("PP20 literal exceeds output bounds")
            for _ in range(length):
                cursor -= 1
                out[cursor] = bits(8)
            if cursor == 0:
                break
        selector = bits(2)
        width = data[4 + selector]
        if not 1 <= width <= 16:
            raise ValueError("Invalid PP20 offset width")
        length = selector + 2
        if selector == 3:
            if bits(1) == 0:
                width = 7
            offset = bits(width)
            while True:
                part = bits(3)
                length += part
                if part != 7:
                    break
        else:
            offset = bits(width)
        if length > cursor or cursor + offset >= size:
            raise ValueError("PP20 back-reference exceeds output bounds")
        for _ in range(length):
            out[cursor - 1] = out[cursor + offset]
            cursor -= 1
    return bytes(out)
