#!/bin/bash
#
#  LAG TALE MED DIN STEMME
#  -----------------------
#  Leser teksten fra tekst/teksten.txt og lager tale i output/tale.wav
#
#  Kjør med:
#      ./scripts/lag_tale.sh
#
#  For å endre teksten: rediger tekst/teksten.txt
#  For å endre modell:   se README.md
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROT="$(dirname "$SCRIPT_DIR")"

MODELL="${MODELL:-full}"
case "$MODELL" in
  full)
    GGUF="$ROT/modeller/drama-3-backbone-4bit-experts-Q4_K_S.gguf"
    ;;
  small)
    GGUF="$ROT/modeller/drama3-small-IQ3_XXS.gguf"
    ;;
  *)
    echo "Ukjent modell: $MODELL (bruk 'full' eller 'small')" >&2
    exit 1
    ;;
esac

TEXTSFIL="${TEKSTFIL:-$ROT/tekst/teksten.txt}"
STEMME="${STEMME:-$ROT/referanse/stemme.wav}"
TRANSKRIPT="${TRANSKRIPT:-$ROT/referanse/transkript.txt}"
UTGAVE="${UTGAVE:-$ROT/output/tale.wav}"

for f in "$ROT/bin/audiocpp_cli" "$GGUF" "$TEXTSFIL" "$STEMME" "$TRANSKRIPT"; do
    if [ ! -f "$f" ]; then
        echo "Mangler: $f" >&2
        case "$f" in
          *audiocpp_cli*) echo "  Kjør ./installer.sh først." >&2 ;;
          *referanse*)    echo "  Kjør ./scripts/forbered_referanse.wav <din-stemme.wav>" >&2 ;;
          *teksten.txt*)  echo "  Lag filen tekst/teksten.txt med teksten du vil lese." >&2 ;;
        esac
        exit 1
    fi
done

mkdir -p "$ROT/output"

TALE="$(cat "$TEXTSFIL")"
REFTEKST="$(cat "$TRANSKRIPT")"

echo "→  Starter Fish Audio Drama 3 ..."
echo "   Modell    : $(basename "$GGUF")"
echo "   Tekst     : ${TALE:0:70}..."
echo "   Referanse : $(basename "$STEMME")"
echo ""
echo "   Dette tar et par minutter. Full modell med ekspert-offloading"
echo "   bruker mye disk, så tål at det går litt treigere."
echo ""

# Flaggene under er det som gjør at modellen passer på en Mac med 16 GB RAM.
#
#   disk_experts=true     ekspertene ligger på disk og strømmes inn
#                          mens de brukes. Uten dette ville 22 GB modellen
#                          ikke fått plass i 16 GB RAM.
#   expert_cache_size=8   hvor mange eksperter som holdes i RAM om gangen.
#                          8 = minst RAM. 32 = færre disk-lesninger.
#   cpu_expert_layers=0   ekspertene kjøres fortsatt på GPU-en (Metal).
#   codec_backend=cpu     flytter lydkoderen (747 MB) ut av GPU-minnet.
#   codec_encoder_chunk_samples
#                          deler referanse-encodingen i biter, slik at
#                          toppminnet blir lavere.
exec "$ROT/bin/audiocpp_cli" \
    --task clon \
    --family fish_drama3 \
    --backend metal \
    --mode offline \
    --model "$GGUF" \
    --voice-ref "$STEMME" \
    --request-option "reference_text=$REFTEKST" \
    --text "$TALE" \
    --max-tokens "${MAX_TOKENS:-700}" \
    --seed 42 \
    --threads 10 \
    --session-option fish_drama3.disk_experts=true \
    --session-option "fish_drama3.expert_cache_size=${CACHE_SIZE:-8}" \
    --session-option fish_drama3.cpu_expert_layers=0 \
    --session-option fish_drama3.context_length=2048 \
    --session-option fish_drama3.codec_backend=cpu \
    --session-option fish_drama3.codec_encoder_chunk_samples=65536 \
    --metrics \
    --out "$UTGAVE"

echo ""
echo "✔  Ferdig: $UTGAVE"
echo ""
echo "   For å høre:  open \"$UTGAVE\""
