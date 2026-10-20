#!/usr/bin/env python3
"""Sammenlign WER for Drama 3, CosyVoice3 og Chatterbox v3."""
import glob
import os
import re
import warnings

warnings.filterwarnings("ignore")
import whisper  # noqa: E402

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


CANDIDATES = [
    ("Drama 3 Q4_K_S", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_full_q4k.wav", "no", NO_REF, "norsk"),
    ("Drama 3 Q4_K_S", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_full_q4k_varianter.wav", "no", NO_REF, "norsk"),
    ("Drama 3 small", "/Users/sondre/fish-drama3-norsk-guide/audio/norsk_small_ubrukelig.wav", "no", NO_REF, "norsk"),
    ("CosyVoice3+LoRA", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_norsk.wav", "no", NO_REF, "norsk"),
    ("Chatterbox v3", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_norsk.wav", "no", NO_REF, "norsk"),
    ("Drama 3 Q4_K_S", "/Users/sondre/fish-drama3-norsk-guide/audio/engelsk_full_q4k.wav", "en", EN_REF, "engelsk"),
    ("CosyVoice3+LoRA", "/Users/sondre/CosyVoice/sammenligning/cosyvoice_engelsk.wav", "en", EN_REF, "engelsk"),
    ("Chatterbox v3", "/Users/sondre/chatterbox_v3/sammenligning/chatterbox_engelsk.wav", "en", EN_REF, "engelsk"),
]

model = whisper.load_model("small")
print(f"{'Modell':<18} {'Språk':<9} {'WER':>7}  {'Auto':<5}  tekst")
print("-" * 100)
for name, path, lang, ref, sprak in CANDIDATES:
    if not os.path.exists(path):
        print(f"{name:<18} {sprak:<9}  FIL MANGLER")
        continue
    res = model.transcribe(path, language=lang)
    w = wer(norm(ref), norm(res["text"]))
    auto = model.transcribe(path).get("language", "?")
    print(f"{name:<18} {sprak:<9} {w * 100:6.1f}%  {auto:<5}  {res['text'].strip()[:120]}")
    print()
