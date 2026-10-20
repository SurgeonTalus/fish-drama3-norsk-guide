#!/bin/bash
#
#  Q2_K-test: to varianter av Drama 3 35B (Q2_K) på M1 Pro 16 GB
#  ------------------------------------------------------------------
#  Runde 1: disk_experts=true  — ekspertene strømmes fra disk
#  Runde 2: disk_experts=false — Hele modellen forsøkes lastet i RAM
#
#  Kjøres automatisk kl. 04:00. Resultater i out/.
#
set -u
cd /Users/sondre/fish_drama3_35b_exert_offloading
mkdir -p out

MODEL="models/drama-3-backbone-8bit-experts-Q2_K.gguf"
REF_TEXT="I dag skal vi lage et ukebladportrett med collage! Men hva er egentlig et ukebladportrett? Et portrett er et bilde av et menneske. Når vi lager et ukebladportrett, bruker vi bilder fra blader til å sette sammen et nytt ansikt."
TTS_TEXT="Mal et A4-ark i grønne og gule nyanser. Mal en stor sirkel på 25,5 cm og fyll hele sirkelen med farge."

# ── Vent til 04:00 ─────────────────────────────────────────────
while [ "$(date +%H%M)" != "0400" ]; do sleep 30; done
sleep 45

# ── Frigjøre minne: Draw Things må ned (bruker GPU-en) ────────
pkill -f "draw-things-cli" 2>/dev/null
pkill -f "Draw Things" 2>/dev/null
pkill -f "drawthings-openai-watcher" 2>/dev/null
sleep 12
pkill -f "audiocpp_cli" 2>/dev/null
sleep 5

{
  echo "=== Q2_K-test startet $(date) ==="
  echo "--- RAM før test ---"
  top -l 1 -n 0 | grep PhysMem
  sysctl vm.swapusage
  echo
} > out/q2k_resultat.txt

if [ ! -f "$MODEL" ]; then
    echo "FEIL: modellen mangler: $MODEL" >> out/q2k_resultat.txt
    exit 1
fi

# ── Overvåker swap + minne i bakgrunnen ──────────────────────
monitor() {
    local label="$1" log="$2"
    while true; do
        local sw used
        sw=$(sysctl -n vm.swapusage | grep -oE 'used = [0-9.]+M' | grep -oE '[0-9.]+')
        used=$(top -l 1 -n 0 | grep PhysMem | sed 's/PhysMem: //')
        echo "$(date +%H:%M:%S) swap=${sw}M | $used" >> "$log"
        sleep 20
    done
}

run_variant() {
    local label="$1" outwav="$2"; shift 2
    local log="out/q2k_${label}.log"
    local swaplog="out/q2k_${label}_swap.log"
    : > "$swaplog"

    {
        echo "=== Variant: $label ==="
        echo "Start: $(date)"
        echo "Parametere: $*"
        echo
    } >> out/q2k_resultat.txt

    monitor "$label" "$swaplog" &
    local monpid=$!

    local start end
    start=$(date +%s)
    caffeinate -dimsu ./bin/audiocpp_cli \
        --task clon --family fish_drama3 --backend metal --mode offline \
        --model "$MODEL" \
        --voice-ref ref/voice_ref_8s.wav \
        --request-option "reference_text=$REF_TEXT" \
        --text "$TTS_TEXT" \
        --max-tokens 400 --seed 42 --threads 10 \
        "$@" \
        --session-option fish_drama3.context_length=2048 \
        --session-option fish_drama3.codec_backend=cpu \
        --session-option fish_drama3.codec_encoder_chunk_samples=65536 \
        --log --metrics --out "$outwav" > "$log" 2>&1
    local rc=$?
    end=$(date +%s)

    kill $monpid 2>/dev/null

    {
        echo "  exit-kode:      $rc"
        echo "  wall-tid:       $((end-start)) s"
        echo "  peak swap:      $(grep -oE 'swap=[0-9.]+M' "$swaplog" | grep -oE '[0-9.]+' | sort -rn | head -1) MB"
        if [ -f "$outwav" ]; then
            echo "  lyd:            OK ($(stat -f%z "$outwav") bytes)"
        else
            echo "  lyd:            IKKE PRODUSERT (prosessen avsluttet)"
        fi
        echo
    } >> out/q2k_resultat.txt
}

# ── Runde 1: disk-backed expert offloading ─────────────────────
run_variant "offload" "out/q2k_norsk_offload.wav" \
    --session-option fish_drama3.disk_experts=true \
    --session-option fish_drama3.expert_cache_size=8 \
    --session-option fish_drama3.cpu_expert_layers=0

sleep 20

# ── Runde 2: hele modellen i RAM (forventes å swappe / dø) ─────
run_variant "resident" "out/q2k_norsk_resident.wav" \
    --session-option fish_drama3.disk_experts=false \
    --session-option fish_drama3.cpu_expert_layers=0

{
    echo "--- RAM etter test ---"
    top -l 1 -n 0 | grep PhysMem
    sysctl vm.swapusage
    echo "Ferdig: $(date)"
} >> out/q2k_resultat.txt

echo "DONE" > out/q2k_done.flag
