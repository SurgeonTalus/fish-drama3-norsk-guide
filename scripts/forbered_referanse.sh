#!/bin/bash
#
#  FORBERED EN REFERANSELYD
#  --------------------------
#  Gjør en valgt stemmeprøve klar til kloning.
#
#  Kjør med:
#      ./scripts/forbered_referanse.wav ~/path/til/din/stemme.wav
#
#  Hva gjør dette:
#    - kutter ned til de første 8 sekundene (anbefalt på 16 GB Mac)
#    - gjør om til 44,1 kHz mono (det formatet Drama 3 lager lyd i)
#    - lager også en transkripsjon-fil du kan redigere
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROT="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
    echo "Bruk: $(basename "$0") <din-stemme.wav> [sekunder]" >&2
    exit 1
fi

IN="$1"
SEKUNDER="${2:-8}"

if [ ! -f "$IN" ]; then
    echo "Fant ikke filen: $IN" >&2
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg mangler. Kjør: brew install ffmpeg" >&2
    exit 1
fi

mkdir -p "$ROT/referanse"

# 44,1 kHz mono, PCM 16-bit
ffmpeg -y -i "$IN" -t "$SEKUNDER" -ar 44100 -ac 1 -c:a pcm_s16le \
    "$ROT/referanse/stemme.wav" 2>/dev/null

echo "✔  Ferdig: $ROT/referanse/stemme.wav"
ffprobe -v error -show_entries stream=sample_rate,channels \
         -show_entries format=duration -of default=nw=1 \
         "$ROT/referanse/stemme.wav" | sed 's/^/    /'

# Transkripsjon-mal. Hvis du vet hva som blir sagt, skriv det her —
# modellen trenger denne teksten for å klone stemmen korrekt.
if [ ! -f "$ROT/referanse/transkript.txt" ]; then
    cat > "$ROT/referanse/transkript.txt" << 'EOF'
SKRIV HER HVA DET BLIR SATT I REFERANSELYDEN.
For eksempel: "I dag skal vi lage et ukebladportrett med collage!"
EOF
    echo ""
    echo "→  Rediger transkriptet: $ROT/referanse/transkript.txt"
    echo "   (Dette er viktig for at kloningen skal bli riktig)"
else
    echo "✔  Transkript finnes allerede: $ROT/referanse/transkript.txt"
fi
