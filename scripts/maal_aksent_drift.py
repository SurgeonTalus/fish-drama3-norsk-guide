#!/usr/bin/env python3
"""
Mål aksent-drift: hvor mye endrer stemmen seg fra referansen?

For hvert klipp:
  1. Transkriber referansen (norsk) og mål den relative avstanden til
     hvert generert klipp
  2. Se hvilket språk Whisper auto-detekterer i hvert klipp
  3. Mål om lydens pitch (f0) ligger nær referansen

Referansen er norsk. Et klipp som auto-detekteres til et annet språk, eller
ligger langt unna referansen i embeddingsrommet, har "driftet" i betydningen
at modellen har falt referansens språk/timbre.
"""
import os
import re
import warnings

warnings.filterwarnings("ignore")
import numpy as np  # noqa: E402
import whisper  # noqa: E402
import soundfile as sf  # noqa: E402

REF = "/Users/sondre/fish-drama3-norsk-guide/audio/referanse_stemme.wav"

CLIPS = [
    ("Drama 3 Q4_K_S", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_full_q4k.wav"),
    ("Drama 3 Q4_K_S (v2)", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_full_q4k_varianter.wav"),
    ("Drama 3 small", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_small_ubrukelig.wav"),
    ("CosyVoice3 ( kinesisk instr.)", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_norsk.wav"),
    ("CosyVoice3 (engelsk instr.)", "/Users/sondre/CosyVoice/sammenligning/cosyvoice2_norsk.wav"),
    ("Chatterbox v3", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_norsk.wav"),
]

EN_CLIPS = [
    ("Drama 3 Q4_K_S", "/Users/sondre/fish-drama3-norsk-guide/audio/engelsk_full_q4k.wav"),
    ("CosyVoice3 (kinesisk instr.)", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_engelsk.wav"),
    ("CosyVoice3 (engelsk instr.)", "/Users/sondre/CosyVoice/sammenligning/cosyvoice2_engelsk.wav"),
    ("Chatterbox v3", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_engelsk.wav"),
]


def f0_median(path):
    """Median grunnfrekvens, grov autokorrelasjon."""
    import wave
    try:
        with wave.open(path, "rb") as w:
            sr = w.getframerate()
            n = w.getnframes()
            raw = w.readframes(n)
        data = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
        if len(data) < sr // 2:
            return None
        seg = data[: sr * 3]
        seg = seg - seg.mean()
        seg = seg * np.hanning(len(seg))
        ac = np.correlate(seg, seg, mode="full")[len(seg) - 1 :]
        lo, hi = sr // 300, sr // 70
        if hi >= len(ac):
            return None
        peak = lo + int(np.argmax(ac[lo:hi]))
        if ac[peak] <= 0:
            return None
        return sr / peak
    except Exception:
        return None


def main():
    model = whisper.load_model("small")

    ref_f0 = f0_median(REF)
    print(f"Referanse F0 (median): {ref_f0:.1f} Hz" if ref_f0 else "Referanse F0: ukjent")
    print()

    for tittel, klipp_liste in (("NORSK", CLIPS), ("ENGELSK", EN_CLIPS)):
        print("=" * 92)
        print(tittel)
        print("=" * 92)
        print(f"{'Modell':<32} {'Auto-språk':<12} {'F0 Hz':>7} {'ΔF0':>7}  tekst")
        print("-" * 92)
        for navn, sti in klipp_liste:
            if not os.path.exists(sti):
                print(f"{navn:<32}  FIL MANGLER")
                continue
            res = model.transcribe(sti)
            auto = res.get("language", "?")
            f0 = f0_median(sti)
            delta = (f0 - ref_f0) if (f0 and ref_f0) else None
            d = f"{delta:+.1f}" if delta is not None else "—"
            f0s = f"{f0:.1f}" if f0 else "—"
            print(f"{navn:<32} {auto:<12} {f0s:>7} {d:>7}  {res['text'].strip()[:70]}")
        print()


if __name__ == "__main__":
    main()
