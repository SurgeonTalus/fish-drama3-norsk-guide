# Naturlig TTS på norsk med Fish Audio Drama 3

**Lag tale på norsk med din egen stemme — direkte på en Mac med 16 GB RAM.**

Denne guiden viser hvordan du kjører [Fish Audio Drama 3](https://huggingface.co/fishaudio/drama-3)
på en MacBook Pro med M1/M1 Pro og 16 GB RAM, slik at den leser norsk tekst med
en stemme du har tatt opp selv.

Modellen er stor (22 GB) og ble laget for NVIDIA-grafikkort. Med
**ekspert-offloading** — en funksjon i [audio.cpp](https://github.com/0xShug0/audio.cpp)
som strømmer modellvektene fra disk mens de brukes — får den likevel plass på
en Mac med 16 GB RAM. Vi målte **6,9 GB** i minnebruk under en lang tale.

> **Resultatet:** norsk som høres ut som norsk. Ordfeilrate **36 %** mot
> **59 %** for den lille modellen. Se [`docs/RAPPORT.md`](docs/RAPPORT.md).

---

## Innhold

1. [Hva du trenger](#hva-du-trenger)
2. [Installasjon i 3 steg](#installasjon-i-3-steg)
3. [Lage tale](#lage-tale)
4. [Forskjell på modellene](#forskjell-på-modellene)
5. [Verdien du får](#verdien-du-får)
6. [Nyttig å vite](#nyttig-å-vite)
7. [Ordbok](#ordbok)
8. [Feilsøking](#feilsøking)

---

## Hva du trenger

| | |
|---|---|
| **Maskin** | Mac med Apple Silicon (M1, M1 Pro, M2, M3, M4) |
| **RAM** | 16 GB (anbefales) — 8 GB fungerer med den lille modellen |
| **Disk** | 30 GB ledig (22 GB til modellen + resten) |
| **Nett** | Trenger 22 GB nedlasting |
| **Tid** | 15–20 min for installasjon |

Krav på CUDA/NVIDIA? Nei. Alt kjøres på Macens egen GPU via **Metal**.

---

## Installasjon i 3 steg

### Steg 1 — Last ned

```bash
git clone https://github.com/SurgeonTalus/fish-drama3-norsk-guide.git
cd fish-drama3-norsk-guide
```

### Steg 2 — Kjør installasjonen

```bash
./installer.sh
```

Scriptet sjekker maskinen, installerer `ffmpeg`, laster ned runtime-en
(~32 MB) og modellen (22 GB). Det tar 15–20 minutter.

> **Har du bare 8 GB RAM?** Bruk den lille modellen (9,7 GB, raskere):
> ```bash
> MODELL=small ./installer.sh
> ```

### Steg 3 — Forbered stemmen din

Finn en opptakelse av deg selv, 10–30 sekunder, der du leser noe
naturlig. Lagre den som `min-stemme.wav` og kjør:

```bash
./scripts/forbered_referanse.sh ~/Desktop/min-stemme.wav
```

Scriptet kutter til 8 sekunder, gjør om til 44,1 kHz mono, og lager
`referanse/transkript.txt`.

**Åpne `referanse/transkript.txt` og skriv inn hva du sa.** Modellen trenger
denne teksten for å klone stemmen din korrekt. Gjør du det ikke, blir
resultatet dårlig.

---

## Lage tale

Skriv teksten du vil lest i `tekst/teksten.txt`, så:

```bash
./scripts/lag_tale.sh
```

Ferdig lyd ligger i `output/tale.wav`. Høre på den:

```bash
open output/tale.wav
```

**Tips for best resultat:**

- Skriv tall ut som ord. «25,5 cm» blir ofte misforstått — skriv
  «tjugfemfem centimeter».
- En setning per tanke. Pause i teksten blir til pause i talen.
- Hold teksten under ca. 40 ord for raskest resultat.

### Egne innstillinger

```bash
# Raskere (mindre ekspert-cache, mindre RAM)
CACHE_SIZE=8 ./scripts/lag_tale.sh

# Færre disk-lesninger, mer RAM
CACHE_SIZE=32 ./scripts/lag_tale.sh

# Kortere tale
MAX_TOKENS=300 ./scripts/lag_tale.sh

# Engelsk
TEKSTFIL=tekst/eksempel_engelsk.txt ./scripts/lag_tale.sh
```

---

## Forskjell på modellene

To versjoner finnes. Begge er testet på samme maskin.

| | **Q4_K_S (full)** | **IQ3_XXS (liten)** |
|---|---|---|
| Størrelse | 22 GB | 9,7 GB |
| Trenger ekspert-offloading | **Ja** | Nei |
| Minnebruk under tale | 6,9 GB | 10,3 GB |
| Norsk | **Riktig** | Uselig |
| Engelsk | Riktig | Riktig |
| Hastighet (RTF) | 28,8 | **4,7** |
| Språk i modellen | 83 språk | japansk + engelsk |

**Kort fortalt:**

- **Q4_K_S** er den du vil ha. Norsk fungerer, og 83 språk er dekket.
- **IQ3_XXS** er 6x raskere, men lært på japansk og engelsk. Norsk blir
  rot. Den er ment som et eksperiment.

Høre forskjellen på norsk:

- [`audio/norsk_full_q4k.wav`](audio/norsk_full_q4k.wav) — Q4_K_S, riktig norsk
- [`audio/norsk_full_q4k_varianter.wav`](audio/norsk_full_q4k_varianter.wav) — Q4_K_S, en bedre kjøring
- [`audio/norsk_small_ubrukelig.wav`](audio/norsk_small_ubrukelig.wav) — IQ3_XXS, ubrukelig

> **Merk:** de to Q4_K_S-klippene er fra to kjøringer med identisk oppsett.
> Den ene fikk «25,5 cm» riktig, den andre fikk «5-12 cm». Tall i teksten er
> den mest ustabile delen — skriv dem ut som ord.

---

## Lydeksempler

| Fil | Hva det er | Lengde |
|---|---|---|
| [`audio/norsk_full_q4k.wav`](audio/norsk_full_q4k.wav) | Q4_K_S, norsk kloning | 8,4 s |
| [`audio/norsk_full_q4k_varianter.wav`](audio/norsk_full_q4k_varianter.wav) | Q4_K_S, norsk kloning (bedre kjøring) | 9,0 s |
| [`audio/norsk_small_ubrukelig.wav`](audio/norsk_small_ubrukelig.wav) | IQ3_XXS, norsk — ubrukelig | 9,3 s |
| [`audio/engelsk_full_q4k.wav`](audio/engelsk_full_q4k.wav) | Q4_K_S, engelsk kloning | 33,1 s |
| [`audio/benchmark_small_gpu.wav`](audio/benchmark_small_gpu.wav) | IQ3_XXS, ren TTS (RTF 4,7) | 2,8 s |
| [`audio/referanse_stemme.wav`](audio/referanse_stemme.wav) | Referanseklippet som ble brukt | 8,0 s |

Alle er 44,1 kHz mono PCM 16-bit.

---

## Verdien du får

### Full oversikt over målingene

Se [`docs/RAPPORT.md`](docs/RAPPORT.md) for hele rapporten med hastighet,
presisjon og hvordan offloadingen virker.

**Kortversjonen:**

| Måltall | Q4_K_S | IQ3_XXS |
|---|---|---|
| Norsk, ordfeilrate | **18–36 %** | 59 % |
| Engelsk, ordfeilrate | **6 %** | — |
| Hastighet (RTF, lavere er bedre) | 27–29 | **4,7** |
| Minnebruk | **6,9 GB** | 10,3 GB |
| Disk lest for 33 s tale | 351 GB | 0 |

### Sammenligning med en M3 Ultra

[drama3-mac](https://github.com/JordiPosthumus/drama3-mac) av Jordi Posthumus er
en egen **MLX**-port av Drama 3 med sterke resultater på **M3 Ultra med 512 GB
RAM**. Modellen er der **fullt resident** i RAM, og den bruker Apples eget
rammeverk i stedet for GGUF/ggml.

| | **M3 Ultra + MLX** | **M1 Pro 16 GB + audio.cpp** |
|---|---|---|
| Modell i RAM | Fullt resident, 27,3 GB | Disk-offload, 6,9 GB |
| Disk lest pr. 33 s | 0 | 351 GB |
| **RTF** | **0,68** | **28,8** |

**Forskjellen er ~42x**, men den skyldes **innstillingene og maskinen**, ikke
modellen:

1. På M3 Ultra er modellen resident — ingenting leses fra disk. På 16 GB er
   disk-offloading **tvunget**, og derfor er 351 GB disklesing 75 % av tiden.
2. M3 Ultra har rundt 800 GB/s minnebåndbredde mot rundt 200 GB/s for M1 Pro.
3. MLX bruker `mx.compile` og fjerner CPU-dispatch-overhead som ggml betaler.
4. drama3-mac beholder projeksjonene i **bf16** (slik som den offisielle
   FP8-utgivelsen) og kvantiserer bare ekspertene. Q4_K_S kvantiserer også
   ryggraden.

På en M3 Ultra med nok RAM er drama3-mac klart raskere. På 16 GB finnes ikke
det alternativet — modellen kan ikke holdes resident, så offloading er ikke
en optimalisering men en nødvendighet.

Flinke funn fra drama3-mac som er verdt å bruke:
- **30 sekunders referanse med flere opptak** holder stemmen bedre enn ett
  kort opptak (cosinus 0,939 mot 0,895)
- **«Kald» sampling for fortelling:** `temperature 0.7, top_p 0.85`
- **Aldri kvantiser projeksjonene** — det gir flytende gibberish

---

## Nyttig å vite

### Hvor lang tid tar det?

| Hva | Tid |
|---|---|
| 33 s tale, Q4_K_S | ~16 minutter |
| 8 s tale, Q4_K_S | ~4 minutter |
| 3 s tale, IQ3_XXS | 13 sekunder |

Ja, den store modellen er treg på en Mac. Grunnen er at ekspertene må leses fra
disk: 351 GB for en 33 sekunders tale. På en rask SSD går det, men det er
disken som er flaskehalsen.

**Tips:** lag kortere klipp, eller bruk den lille modellen mens du jobber og
den store til slutt.

### Kan jeg bruke stemmen til andre?

Ja, så lenge det er **din egen** stemme eller noen har gitt samtykke.
Modelllisensen (Fish Audio Community License) tillater forskning og
ikke-kommersiell bruk, og begrenser kommersiell bruk til under 500 000 USD
i årlig omsetning. Å tilby modellen som en betalt tjeneste krever egen
lisens fra Fish Audio.

### Bruker du Linux eller Windows?

Guiden er for macOS. På Linux/Windows med NVIDIA-kort kan du bruke
[vLLM-Omni](https://recipes.vllm.ai/fishaudio/drama-3) eller
[SGLang-Omni](https://sgl-project.github.io/sglang-omni/cookbook/fishaudio_drama3.html)
med den offisielle modellen. Da trenger du et grafikkort med minst 48 GB.

---

## Ordbok

Forkortelser og fagord du møter i loggene og i dokumentasjonen.

###Ytelse og minne

| Forkortelse | Betydning | Forklaring |
|---|---|---|
| **RTF** | Real-Time Factor | Hvor mange ganger så lang tid brukte maskinen som lydens lengde. RTF 4,7 betyr at 1 sekund lyd tok 4,7 sekunder. **Lavere er bedre.** RTF 1,0 betyr «i sanntid». |
| **WER** | Word Error Rate | Ordfeilrate. Andelen ord i den genererte lyden som er feil sammenlignet med teksten du skrev. **Lavere er bedre.** 0 % = ordrett. |
| **CER** | Character Error Rate | Samme som WER, men per tegn i stedet for per ord. |
| **VRAM** | Video RAM | Minne på grafikkortet. På Mac finnes ikke dette separat — GPU og CPU deler samme minne. |
| **Unified memory** | Enhetsminne | Mac-teknologi der CPU og GPU deler ett minnespor. Derfor kan en Mac med 16 GB kjøre en 22 GB-modell. |
| **Swap** | Byttefil | Når minnet blir fullt, legger macOS data på disk. Mye swap = alt blir tregt, og prosesser kan bli avsluttet uten varsel. |
| **Footprint** | Minnebruk | Hvor mye minne prosessen faktisk bruker. |

### Modell og vekter

| Forkortelse | Betydning | Forklaring |
|---|---|---|
| **TTS** | Text-to-Speech | Tale fra tekst. |
| **ASR** | Automatic Speech Recognition | Tale til tekst. |
| **MoE** | Mixture of Experts | En modell der bare noen «eksperter» aktiveres per ord. Drama 3 har 35 milliarder parametere, men bruker bare 3 milliarder om gangen. |
| **A3B** | Active 3B | 35B totalt, 3B aktive per token. |
| **GGUF** | GGML Format | Filformatet modellene ligger i. Kan leses direkte uten å pakke om. |
| **Q4_K_S** | 4-bits kvantisering | Vektene er komprimert til 4 bit. Kvaliteten er nesten like god som full presisjon, men filen blir mye mindre. |
| **IQ3_XXS** | 3-bits kvantisering | Enda mindre og raskere, men med mer kvalitetstap. |
| **FP8 / BF16 / FP16** | Flyt-tallsformater | Full presisjon. 8-, 16- og 32-bit. |
| **Bit per weight (bpw)** | Biter per vekt | 2,13 bpw for Q4_K_S. Det er grunnen til at 35B-modellen blir 22 GB i stedet for 70 GB. |
| **LoRA** | Low-Rank Adaptation | Liten ekstra treningsfil som tilpasser en stor modell. |
| **Hadamard-rotasjon** | — | En matematisk transformasjon modellen bruker. Derfor kan ikke vanlig llama.cpp lese filene — det trengs en egen runtime. |

### Runtime og inferens

| Forkortelse | Betydning | Forklaring |
|---|---|---|
| **Metal** | — | Apples grafikk-API. Tilsvarer CUDA på NVIDIA-kort. |
| **CUDA** | — | NVIDIAs grafikk-API. Drama 3 er bygget for dette. |
| **CPU / GPU** | — | Hvilken prosessor som utfører arbeidet. |
| **Prefill** | — | Når modellen leser hele teksten og referansen på forhånd. Koster tid før talen begynner. |
| **Decode** | — | Når modellen genererer lyd ord for ord. |
| **Context / kontekstvindu** | — | Hvor mye tekst og lyd modellen holder i minnet samtidig. |
| **KV-cache** | — | Mellomresultatene for hvert ord, så modellen ikke må regne ut igjen. Lager minne. |
| **Codebook / MTP** | Multi-Token Prediction | Modellen lager lyd ved å velge fra et sett lydbiter. |
| **Disk-backed expert offloading** | Ekspert-offloading fra disk | Ekspertene ligger på disk og strømmes inn i RAM mens de brukes. Dette er nøkkelen til at 22 GB får plass på 16 GB. |
| **Expert cache** | Ekspert-cache | Hvor mange eksperter som holdes i RAM om gangen (8–256). Større tall = færre disk-lesninger, mer RAM. |

---

## Feilsøking

**«Processen dør med ingen feilmelding»**
Macen har gått tom for minne. Sjekk `sysctl vm.swapusage`. Løsning: kortere
referanse (8 sekunder), og `codec_backend=cpu` (allerede satt opp).

**«Norsk lyder rart»**
- Sjekk at `referanse/transkript.txt` faktisk inneholder det som ble sagt
- Skriv tall ut som ord
- Prøv den store modellen: `MODELL=full`

**«Det går utrolig langsomt»**
- Forventet med den store modellen. Kortere tekst = raskere.
- Prøv `CACHE_SIZE=32` for færre disk-lesninger
- Eller bruk `MODELL=small ./installer.sh` til prototyping

**«ffmpeg mangler»**
```bash
brew install ffmpeg
```

**«Permission denied» når du kjører et script**
```bash
chmod +x installer.sh scripts/*.sh
```

**Første gangs kjøring tar 2–3 minutter ekstra**
Metal bygger grafikk-kjernene sine. Det lagres og går raskere neste gang.

---

## Koblinger

### Prosjekter vi har brukt

| Prosjekt | Hva det er | Lenke |
|---|---|---|
| **Fish Audio Drama 3** | Modellen. 35B MoE, 83 språk, Apache 2.0 | [huggingface.co/fishaudio/drama-3](https://huggingface.co/fishaudio/drama-3) |
| **audio.cpp** | Runtime-en vi bruker. Rent C++, 62 modellfamilier, Metal-støtte | [github.com/0xShug0/audio.cpp](https://github.com/0xShug0/audio.cpp) |
| **audio.cpp — Drama 3-dokumentasjon** | All konfigurasjon for ekspert-offloading | [docs/models/fish_drama3.md](https://github.com/0xShug0/audio.cpp/blob/main/docs/models/fish_drama3.md) |
| **audio.cpp — nedlastinger** | Ferdige macOS-bygg | [releases](https://github.com/0xShug0/audio.cpp/releases) |
| **JarodMica/Drama-3-GGUF** | GGUF-konverteringen vi bruker (Q4_K_S) | [huggingface.co/Jmica/Drama-3-GGUF](https://huggingface.co/Jmica/Drama-3-GGUF) |
| **pentacoxian-dev/drama3-small-GGUF** | Den lille modellen (IQ3_XXS) | [huggingface.co/pentacoxian-dev/drama3-small-GGUF](https://huggingface.co/pentacoxian-dev/drama3-small-GGUF) |
| **PrismML-Eng/llama.cpp** | Prism MLs fork. Også nødvendig for Drama 3 i llama.cpp | [github.com/PrismML-Eng/llama.cpp](https://github.com/PrismML-Eng/llama.cpp) |
| **fish-speech** | Oppstream for modellen og codecen | [github.com/fishaudio/fish-speech](https://github.com/fishaudio/fish-speech) |
| **drama3-mac** | MLX-port av Drama 3 for Mac. Raskeste Mac-alternativet, men krever nok RAM til at modellen blir resident (27,3 GB) | [github.com/JordiPosthumus/drama3-mac](https://github.com/JordiPosthumus/drama3-mac) |

### Alternativer for andre plattformer

| Verktøy | For | Lenke |
|---|---|---|
| **vLLM-Omni** | NVIDIA-GPU, 48 GB+ | [recipes.vllm.ai/fishaudio/drama-3](https://recipes.vllm.ai/fishaudio/drama-3) |
| **SGLang-Omni** | NVIDIA-GPU, høy ytelse | [Cookbook](https://sgl-project.github.io/sglang-omni/cookbook/fishaudio_drama3.html) |
| **Fish Audio Playground** | Prøve modellen i nettleseren | [fish.audio](https://fish.audio) |

### Les mer

| | |
|---|---|
| **Teknisk rapport (Drama 3)** | [arxiv.org/abs/2610.18010](https://arxiv.org/abs/2610.18010) |
| **S2 Pro-rapport (forrige generasjon)** | [arxiv.org/abs/2603.08823](https://arxiv.org/abs/2603.08823) |
| **Vår første rapport (lille modell)** | [fish-audio-drama3-m1-macbook-pro-16gb](https://github.com/SurgeonTalus/fish-audio-drama3-m1-macbook-pro-16gb) |
| **Vår andre rapport (full modell + offloading)** | [fish-audio-drama3-full-35b-expert-offloading](https://github.com/SurgeonTalus/fish-audio-drama3-full-35b-expert-offloading-m1-macbook-pro-16gb) |

---

## Lisens

Denne guiden og scriptene er MIT-lisensert.

Modellene er under **Fish Audio Community License v1.0** — ikke MIT. Se
[lisensen](https://huggingface.co/Jmica/Drama-3-GGUF/blob/main/LICENSE).

Lydklippene i `audio/` er laget med forfatterens egen stemme som referanse, for
å dokumentere resultatene.

---

## Bidrag

Funnet noe galt, eller vil du hjelpe til med norsk? Opprett en issue eller en
pull request.
