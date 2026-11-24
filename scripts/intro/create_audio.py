"""Original draft score and sound effects for intro #16; stdlib only.

Run from any directory with Python 3. No external samples are used.
The two stems are 50 s, mono PCM16 / 22050 Hz; timings follow intro.gd.
"""
from array import array
from pathlib import Path
import json
import math
import random
import sys
import wave

RATE = 22050
DURATION = 50
OUT = Path(__file__).resolve().parents[2] / "godot/scenes/intro/assets"
rng = random.Random(1821)
music = array("f", [0.0]) * (RATE * DURATION)
ambience = array("f", [0.0]) * (RATE * DURATION)


def add(stem, start, samples, gain=1.0):
    offset = round(start * RATE)
    for i, sample in enumerate(samples):
        if 0 <= offset + i < len(stem):
            stem[offset + i] += sample * gain


def pluck(midi, duration=1.8):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    delay = max(2, round(RATE / frequency))
    ring = [rng.uniform(-1, 1) for _ in range(delay)]
    for i in range(round(duration * RATE)):
        j = i % delay
        value = ring[j]
        ring[j] = (value + ring[(j + 1) % delay]) * 0.494
        yield value * min(1.0, i / 70) * min(1.0, (duration * RATE - i) / 500)


def whistle(midi, duration):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    phase = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        phase += 2 * math.pi * frequency * (1 + 0.003 * math.sin(2 * math.pi * 4.7 * t)) / RATE
        envelope = min(1, t / 0.10) * min(1, (duration - t) / 0.19)
        yield (math.sin(phase) + 0.045 * math.sin(2 * phase)) * envelope


def drum(duration=0.45):
    phase = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (58 + 53 * math.exp(-t * 20)) / RATE
        yield (math.sin(phase) * 0.80 + rng.uniform(-1, 1) * math.exp(-t * 35) * 0.20) * math.exp(-t * 10)


# Sparse E-minor motif, composed for this draft; not taken from a film score.
for bar in [4.0, 12.0, 20.0, 31.0, 36.0]:
    for offset, note in [(0, 40), (0.7, 47), (1.4, 52), (2.4, 43)]:
        add(music, bar + offset, pluck(note), 0.21)
    for offset, note, length in [(0.25, 76, 0.65), (1.2, 74, 0.40), (1.95, 71, 1.05)]:
        add(music, bar + offset, whistle(note, length), 0.075)
for beat in [8, 16, 30, 34, 37, 39.5, 41]:
    add(music, beat, drum(), 0.20)
for offset, note in [(0, 40), (0.04, 47), (0.08, 52), (0.12, 55), (0.16, 59)]:
    add(music, 46.7 + offset, pluck(note, 2.3), 0.16)

# Low, slowly changing desert wind, plus a precisely timed fly.
low = 0.0
for i in range(len(ambience)):
    t = i / RATE
    low = low * 0.97 + rng.uniform(-1, 1) * 0.03
    level = 0.11 * (0.7 + 0.3 * math.sin(t * 0.58))
    ambience[i] = low * level
    if 24.0 <= t < 26.35 or 28.15 <= t < 28.8:
        age = t - (24.0 if t < 26.35 else 28.15)
        gain = 0.040 if t < 25 else 0.018
        ambience[i] += gain * (math.sin(t * 2 * math.pi * 175 + 2 * math.sin(t * 33)) + 0.25 * math.sin(t * 2 * math.pi * 350)) * min(1.0, age * 7)

# Shared fades and a suspended beat before the bottle appears.
for stem in [music, ambience]:
    for i in range(len(stem)):
        t = i / RATE
        fade = min(1.0, t / 0.8, (DURATION - t) / 0.8)
        if 43.6 < t < 46.7:
            fade *= max(0.0, 1 - (t - 43.6) / 0.5) if t < 44.1 else 0.0
        stem[i] *= max(0.0, fade)

OUT.mkdir(parents=True, exist_ok=True)
report = {}
for name, stem in [("music", music), ("ambience", ambience)]:
    peak = max(abs(v) for v in stem)
    assert peak < 0.90, (name, peak)
    pcm = array("h", (round(v * 32767) for v in stem))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / (name + ".wav")), "wb") as file:
        file.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        file.writeframes(pcm.tobytes())
    report[name] = {"duration": DURATION, "sample_rate": RATE, "peak": round(peak, 6)}
report["provenance"] = "Composition et synthèse originales pour Tequila Kill ; aucun sample externe. Première proposition sonore à écouter."
(OUT / "audio-provenance.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, ensure_ascii=False))
