#!/bin/bash
# Venter til 04:00, dreper Draw Things, og kjører Q2_K-testen.
# Settes i gang av agenten; resten går automatisk.
cd /Users/sondre/fish-drama3_35b_exert_offloading

# Vent til 04:00
while [ "$(date +%H%M)" != "0400" ]; do sleep 30; done
sleep 60

# Frigjør minne: Draw Things må ned, den bruker GPU-en
pkill -f "draw-things-cli" 2>/dev/null
pkill -f "Draw Things" 2>/dev/null
pkill -f "drawthings-openai-watcher" 2>/dev/null
sleep 10

# Drep eventuelle stale audiocpp-prosesser
pkill -f "audiocpp_cli" 2>/dev/null
sleep 5

MODEL="models/drama-3-backbone-8bit-experts-Q2_K.gguf"
if [ ! -f "$MODEL" ]; then
    echo "FEIL: modellen mangler" > out/q2k_resultat.txt
    exit 1
fi

caffeinate -dimsu ./bin/audiocpp_cli \
    --task clon --family fish_drama3 --backend metal --mode offline \
    --model "$MODEL" \
    --voice-ref ref/voice_ref_8s.wav \
    --request-option "reference_text=I dag skal vi lage et ukebladportrett med collage! Men hva er egentlig et ukebladportrett? Et portrett er et bilde av et menneske. Når vi lager et ukebladportrett, bruker vi bilder fra blader til å sette sammen et nytt ansikt." \
    --text "Mal et A4-ark i grønne og gule nyanser. Mal en stor sirkel på 25,5 cm og fyll hele sirkelen med farge." \
    --max-tokens 400 --seed 42 --threads 10 \
    --session-option fish_drama3.disk_experts=true \
    --session-option fish_drama3.expert_cache_size=8 \
    --session-option fish_drama3.cpu_expert_layers=0 \
    --session-option fish_drama3.context_length=2048 \
    --session-option fish_drama3.codec_backend=cpu \
    --session-option fish_drama3.codec_encoder_chunk_samples=65536 \
    --log --metrics --out out/q2k_norsk.wav > out/q2k_norsk.log 2>&1

echo "DONE" > out/q2k_done.flag
