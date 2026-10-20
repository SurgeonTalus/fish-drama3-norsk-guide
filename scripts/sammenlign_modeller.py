#!/usr/bin/env python3
"""
Sluttoppsummering: Drama 3 vs CosyVoice3 vs Chatterbox v3.

Måler for hvert klipp:
  - WER (ordfeilrate) mot referenceteksten
  - hvilket språk Whisper auto-detekterer (drift-måling)
  - F0 (grunnfrekvens) mot referansen
  - genereringstid og RTF

Alle klipp er generert med SAMME tekst, SAMME referanseklipp og
SAMME maskin.
"""
import os
import re
import warnings

warnings.filterwarnings("ignore")
import numpy as np  # noqa: E402
import whisper  # noqa: E402
import wave  # noqa: E402

BASE = "/Users/sondre/fish-drama3-norsk-guide"
REF = f"{BASE}/audio/referanse_stemme.wav"

NO_REF = "Mal et A4-ark i grønne og gule nyanser. Mal en stor sirkel på 25,5 cm og fyll hele sirkelen med farge."
EN_REF = (
    "I have achieved a high level of proficiency, demonstrated by details such as: "
    "creating varied imprints using different plants, painting the jewelry pieces, "
    "crafting jewelry in various shapes, and investing time and making multiple attempts. "
    "Exploring texture and small-scale craft projects using clay. "
    "Creating clay slabs featuring nature imprints. "
    "Making small jewelry pieces using seashell imprints and paint. "
    "Variety in imprints, creativity in jewelry design, and effort."
)

CLIPS = [
    # (modell, språk, fil, RTF målt, genereringstid)
    ("Drama 3 Q4_K_S", "norsk", f"{BASE}/audio/norsk_full_q4k.wav", 26.3, 220.8),
    ("Drama 3 Q4_K_S (v2)", "norsk", f"{BASE}/audio/norsk_full_q4k_varianter.wav", 27.5, 246.3),
    ("Drama 3 IQ3_XXS", "norsk", f"{BASE}/audio/norsk_small_ubrukelig.wav", 11.2, 104.0),
    ("CosyVoice3 + LoRA", "norsk", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_norsk_v2_engelsk_instr.wav", 10.8, 113.1),
    ("Chatterbox v3", "norsk", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_norsk.wav", 21.8, 163.6),
    ("Drama 3 Q4_K_S", "engelsk", f"{BASE}/audio/engelsk_full_q4k.wav", 28.8, 953.4),
    ("CosyVoice3 + LoRA", "engelsk", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_v2_engelsk.wav", 7.7, 242.7),
    ("Chatterbox v3", "engelsk", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_engelsk.wav", 5.8, 176.5),
]


def norm(t):
    t = t.lower().replace("–", "-").replace("—", "-")
    t = re.sub(r"[^a-z0-9æøå+\-.,% ]", " ", t)
    t = re.sub(r"([.,])", r" \1 ", t)
    return [w for w in t.split() if w not in {".", ","}]


def wer(ref, hyp):
    if not ref:
        return 0.0
    prev = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, 1):
        cur = [i]
        for j, h in enumerate(hyp, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (r != h)))
        prev = cur
    return prev[len(hyp)] / len(ref)


def f0_median(path):
    try:
        with wave.open(path, "rb") as w:
            sr = w.getframerate()
            raw = w.readframes(min(w.getnframes(), sr * 3))
        data = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
        if len(data) < sr // 2:
            return None
        seg = data - data.mean()
        seg = seg * np.hanning(len(seg))
        ac = np.correlate(seg, seg, mode="full")[len(seg) - 1 :]
        lo, hi = sr // 300, sr // 70
        if hi >= len(ac):
            return None
        peak = lo + int(np.argmax(ac[lo:hi]))
        return sr / peak if ac[peak] > 0 else None
    except Exception:
        return None


def main():
    model = whisper.load_model("small")
    ref_f0 = f0_median(REF)
    print(f"Referanse F0: {ref_f0:.1f} Hz\n")

    rows = []
    for navn, sprak, sti, rtf, gen_s in CLIPS:
        if not os.path.exists(sti):
            print(f"MANGLE: {sti}")
            continue
        ref = NO_REF if sprak == "norsk" else EN_REF
        lang = "no" if sprak == "norsk" else "en"
        res = model.transcribe(sti, language=lang)
        auto = model.transcribe(sti).get("language", "?")
        w = wer(norm(ref), norm(res["text"]))
        f0 = f0_median(sti)
        with wave.open(sti, "rb") as wf:
            dur = wf.getnframes() / wf.getframerate()
        delta = (f0 - ref_f0) if (f0 and ref_f0) else 0.0
        rows.append((navn, sprak, w, auto, f0, delta, dur, gen_s, rtf, res["text"].strip()))

    print("=" * 118)
    print(f"{'Modell':<22} {'Språk':<8} {'WER':>7} {'Auto':<5} {'F0':>7} {'ΔF0':>7} {'lyd_s':>7} {'gen_s':>7} {'RTF':>6}")
    print("=" * 118)
    for navn, sprak, w, auto, f0, delta, dur, gen_s, rtf, _ in rows:
        f0s = f"{f0:.1f}" if f0 else "—"
        print(f"{navn:<22} {sprak:<8} {w * 100:6.1f}% {auto:<5} {f0s:>7} {delta:>+7.1f} {dur:7.2f} {gen_s:7.1f} {rtf:6.1f}")

    print()
    print("=" * 118)
    print("TRANSKRIPSJONER")
    print("=" * 118)
    for navn, sprak, w, auto, f0, delta, dur, gen_s, rtf, tekst in rows:
        print(f"\n--- {navn} ({sprak}) WER={w * 100:.1f}% auto={auto} ---")
        print(f"    {tekst}")


if __name__ == "__main__":
    main()
