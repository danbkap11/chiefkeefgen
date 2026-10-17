"""Validate a float32 stereo WAV from tests/render_smoke.scd using Python's standard library."""

import array
import math
import struct
import sys
from pathlib import Path


def check(path: Path, expected_seconds: float) -> None:
    raw = path.read_bytes()
    assert raw[:4] == b"RIFF" and raw[8:12] == b"WAVE", "expected a RIFF WAV"
    offset, fmt, data = 12, None, None
    while offset + 8 <= len(raw):
        name, size = struct.unpack_from("<4sI", raw, offset)
        payload = raw[offset + 8 : offset + 8 + size]
        assert len(payload) == size, "truncated WAV chunk"
        if name == b"fmt ":
            fmt = payload
        elif name == b"data":
            data = payload
        offset += 8 + size + (size % 2)
    assert fmt is not None and data, "missing format or nonempty data chunk"
    kind, channels, rate, _, _, bits = struct.unpack_from("<HHIIHH", fmt)
    if kind == 65534:
        assert len(fmt) >= 40, "truncated extensible format"
        kind = struct.unpack_from("<H", fmt, 24)[0]
    assert (kind, channels, rate, bits) == (3, 2, 48000, 32), "expected 48 kHz stereo float32"
    samples = array.array("f")
    samples.frombytes(data)
    if sys.byteorder != "little":
        samples.byteswap()
    assert all(map(math.isfinite, samples)), "nonfinite samples"
    peak = max(map(abs, samples))
    rms = math.sqrt(sum(x * x for x in samples) / len(samples))
    duration = len(samples) / channels / rate
    assert peak > 0.0001 and rms > 0.000001, "silent output"
    assert peak <= 0.90, f"peak exceeds ceiling: {peak}"
    assert abs(duration - expected_seconds) < 0.10, f"duration mismatch: {duration}"
    print(
        f"WAV CHECK PASSED: float32, {rate} Hz, {channels} channels, "
        f"{len(samples) // channels} frames, {duration:.6f} s, "
        f"peak {peak:.8f}, RMS {rms:.8f}, all samples finite"
    )


if __name__ == "__main__":
    check(Path(sys.argv[1]), float(sys.argv[2]))
