"""Original retro placeholders, synthesized locally with Python's standard library."""
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import wave

HERE = Path(__file__).resolve().parent
RATE = 22050


def render(name, duration, notes, seed):
    samples = [0.0] * round(duration * RATE)
    rng = random.Random(seed)
    for start, length, f0, f1, amplitude, metallic in notes:
        phase = 0.0
        for i in range(round(length * RATE)):
            t = i / RATE
            position = round(start * RATE) + i
            if position >= len(samples):
                break
            progress = t / length
            frequency = f0 * (f1 / f0) ** progress
            phase += 2 * math.pi * frequency / RATE
            # Short band-limited harmonics, fast attack and a soft exponential tail.
            tone = math.sin(phase) + .18 * math.sin(phase * 3) / 3
            tone += metallic * math.sin(phase * 2.73) * math.exp(-progress * 7)
            noise = (rng.random() * 2 - 1) * .045 * math.exp(-progress * 18)
            envelope = min(1, t / .003) * math.exp(-progress * 5) * min(1, (length - t) / .012)
            samples[position] += amplitude * envelope * (tone + noise)
    peak = max(abs(s) for s in samples)
    scale = .62 / peak
    # A little quantization evokes an old console; delivery stays standard PCM16 WAV.
    pcm = [round(round(s * scale * 2047) / 2047 * 32767) for s in samples]
    output = HERE / f'{name}.wav'
    with wave.open(str(output), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack(f'<{len(pcm)}h', *pcm))
    assert max(abs(s) for s in pcm) < 32767
    return {
        'event': name, 'file': output.name, 'duration_seconds': len(pcm) / RATE,
        'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16,
        'peak_dbfs': round(20 * math.log10(max(abs(s) for s in pcm) / 32767), 2),
        'rms_dbfs': round(20 * math.log10(math.sqrt(sum(s*s for s in pcm) / len(pcm)) / 32767), 2),
        'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
        'suggested_gain_db': -3,
    }


files = [
    render('take', .27, [(0, .16, 1100, 1470, .7, .33), (.055, .19, 1650, 2100, .5, .25)], 1),
    render('drop', .24, [(0, .21, 480, 145, .8, .4), (.025, .12, 740, 250, .25, .2)], 2),
    render('empty', .44, [(0, .14, 310, 145, .7, .08), (.10, .14, 255, 110, .65, .08), (.21, .19, 200, 78, .6, .10)], 3),
]
manifest = {
    'issue': 65, 'version': 'v1', 'status': 'fichiers_verifies_valides_producteur', 'validation': 'validation.json',
    'direction': 'sons courts rétro évoquant la SNES, prise claire, perte grave et dernière gorgée',
    'provenance': 'synthèse originale locale, Python standard ; aucun sample tiers, achat ou service de génération',
    'source': 'build.py', 'files': files,
    'checks': {'no_clipping': True, 'finite_duration': True, 'loop': False, 'format': 'WAV PCM16 mono 22050 Hz'},
}
(HERE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'files': len(files), 'format': manifest['checks']['format'], 'no_clipping': True}))
