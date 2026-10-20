#!/bin/bash
#
#  INSTALLASJON AV FISH AUDIO DRAMA 3 PÅ MAC
#  -----------------------------------------
#  Dette scriptet laster ned alt du trenger for å kjøre Fish Audio Drama 3
#  på en Mac med Apple Silicon (M1, M1 Pro, M2, M3, M4...).
#
#  Kjør det med:
#      ./installer.sh
#
#  Varighet: ca. 15-20 minutter (det meste er nedlasting av 22 GB).
#
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  Innstillinger
# ─────────────────────────────────────────────────────────────
MODELL="${MODELL:-full}"        # "full" (anbefalt) eller "small"
INSTALLER_MAPS=(
  [full]="drama-3-backbone-4bit-experts-Q4_K_S.gguf"
  [small]="drama3-small-IQ3_XXS.gguf"
)
RUNTIME_TAG="v0.9.2-drama3-base-small"
RUNTIME_URL="https://github.com/0xShug0/audio.cpp/releases/download/${RUNTIME_TAG}/audio-v0.9.2-drama3-base-small-bin-macos-arm64-metal.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODELLER_DIR="$SCRIPT_DIR/modeller"

# ─────────────────────────────────────────────────────────────
#  Hjelpefunksjoner
# ─────────────────────────────────────────────────────────────
gronn()  { printf "\033[32m✔\033[0m  %s\n" "$*"; }
gul()    { printf "\033[33m!\033[0m  %s\n" "$*"; }
rod()    { printf "\033[31m✘\033[0m  %s\n" "$*" >&2; }
info()   { printf "\033[36m→\033[0m  %s\n" "$*"; }
overskrift() { printf "\n\033[1m%s\033[0m\n" "$*"; }

if [ -t 1 ]; then
  printf "\033[1;35m╔══════════════════════════════════════════╗\033[0m\n"
  printf "\033[1;35m║   FISH AUDIO DRAMA 3 — INSTALLASJON         ║\033[0m\n"
  printf "\033[1;35m╚══════════════════════════════════════════╝\033[0m\n"
fi

# ─────────────────────────────────────────────────────────────
#  Steg 0: Sjekk at vi er på en Mac med Apple Silicon
# ─────────────────────────────────────────────────────────────
overskrift "Steg 0: Sjekker maskinen"

if [ "$(uname -s)" != "Darwin" ]; then
  rod "Dette scriptet er bare for macOS."
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  rod "Dette scriptet krever en Mac med Apple Silicon (M1 eller nyere)."
  rod "Du har: $(uname -m)"
  exit 1
fi

gronn "macOS på Apple Silicon — $(sysctl -n machdep.cpu.brand_string)"

RAM_GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
if [ "$RAM_GB" -lt 16 ]; then
  gul "Du har ${RAM_GB} GB RAM. Anbefales 16 GB eller mer for den store modellen."
  gul "Med mindre RAM kan du bruke den lille modellen: MODELL=small ./installer.sh"
else
  gronn "${RAM_GB} GB RAM"
fi

LEDIG_GB=$(( $(df -k "$SCRIPT_DIR" | tail -1 | awk '{print $4}') / 1048576 ))
if [ "$LEDIG_GB" -lt 30 ]; then
  rod "Du har bare ${LEDIG_GB} GB ledig disk. Modellen trenger 22 GB + 1 GB til runtime."
  exit 1
fi
gronn "${LEDIG_GB} GB ledig disk"

# ─────────────────────────────────────────────────────────────
#  Steg 1: ffmpeg (for å gjøre om referanselyden)
# ─────────────────────────────────────────────────────────────
overskrift "Steg 1: Sjekker ffmpeg"

if ! command -v ffmpeg >/dev/null 2>&1; then
  info "Installerer ffmpeg med Homebrew ..."
  if ! command -v brew >/dev/null 2>&1; then
    rod "Homebrew er ikke installert."
    rod "Installer det med: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    rod "Kjør så installer.sh på nytt."
    exit 1
  fi
  brew install ffmpeg
fi
gronn "ffmpeg: $(ffmpeg -version | head -1 | cut -d' ' -f1-3)"

# ─────────────────────────────────────────────────────────────
#  Steg 2: Hent runtime (audio.cpp, Metal for Apple Silicon)
# ─────────────────────────────────────────────────────────────
overskrift "Steg 2: Laster ned runtime (audio.cpp med Metal)"

mkdir -p "$SCRIPT_DIR/bin"
if [ -f "$SCRIPT_DIR/bin/audiocpp_cli" ]; then
  gronn "Runtime finnes allerede — hopper over."
else
  info "Laster ned ~32 MB ..."
  curl -L --progress-bar -o "$SCRIPT_DIR/bin/runtime.tar.gz" "$RUNTIME_URL"
  tar -xzf "$SCRIPT_DIR/bin/runtime.tar.gz" -C "$SCRIPT_DIR/bin" --strip-components=1
  rm -f "$SCRIPT_DIR/bin/runtime.tar.gz"
  gronn "Runtime installert"
fi

"$SCRIPT_DIR/bin/audiocpp_cli" --version | head -3 | sed 's/^/    /'

# ─────────────────────────────────────────────────────────────
#  Steg 3: Hent modellen
# ─────────────────────────────────────────────────────────────
overskrift "Steg 3: Laster ned modellen ($MODELL)"

case "$MODELL" in
  full)
    FIL="drama-3-backbone-4bit-experts-Q4_K_S.gguf"
    URL="https://huggingface.co/Jmica/Drama-3-GGUF/resolve/main/${FIL}"
    STORRELSE="22 GB"
    ;;
  small)
    FIL="drama3-small-IQ3_XXS.gguf"
    URL="https://huggingface.co/pentacoxian-dev/drama3-small-GGUF/resolve/main/${FIL}"
    STORRELSE="9,7 GB"
    ;;
  *)
    rod "Ukjent modell: $MODELL (bruk 'full' eller 'small')"
    exit 1
    ;;
esac

mkdir -p "$MODELLER_DIR"
if [ -f "$MODELLER_DIR/$FIL" ]; then
  gronn "Modellen finnes allerede — hopper over."
else
  info "Laster ned $STORRELSE. Dette tar 10-15 minutter."
  info "Trykk Ctrl+C hvis du vil avbryte."
  curl -L --progress-bar -o "$MODELLER_DIR/$FIL" "$URL"
  gronn "Modell nedlastet"
fi

ls -lh "$MODELLER_DIR/$FIL" | awk '{print "    Størrelse: " $5}'

# ─────────────────────────────────────────────────────────────
#  Steg 4: Ferdig
# ─────────────────────────────────────────────────────────────
overskrift "Ferdig!"

cat <<EOF

  Alt er på plass. Slik lager du tale:

      cd $(basename "$SCRIPT_DIR")

      # 1. Gjør referanselyden klar (44,1 kHz mono)
      ./scripts/forbered_referanse.wav ~/path/til/din/stemme.wav

      # 2. Lag tale med norsk stemme
      ./scripts/lag_tale.sh

  Åpne README.md for detaljer, eller docs/RAPPORT.md for målinger
  og sammenligning mellom modellene.

EOF

if [ "$MODELL" = "full" ]; then
  info "Husk: modellen på 22 GB trenger 'ekspert-offloading' for å passe i 16 GB RAM."
  info "Det er allerede satt opp i scriptene."
fi
