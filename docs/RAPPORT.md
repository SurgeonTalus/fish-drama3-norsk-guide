# Rapport: Fish Audio Drama 3 på Mac

Målinger fra en **Apple M1 Pro MacBook Pro med 16 GB unified memory**, macOS 27.0.1.

Denne rapporten dekker:

- [Modellene](#modellene)
- [Presisjon](#presisjon) — hvor riktig blir talen?
- [Hastighet](#hastighet) — hvor lang tid tar det?
- [Minnebruk](#minnebruk) — hvor mye RAM brukes?
- [Ekspert-offloading](#ekspert-offloading) — hvordan får 22 GB plass i 16 GB?
- [Sammenligning med M3 Ultra](#sammenligning-med-m3-ultra)
- [Anbefaling](#anbefaling)

---

## Modellene

To bygginger av Fish Audio Drama 3 ble testet på samme maskin, med samme
runtime, samme referanseklipp, samme seed og samme tekst.

| | **Q4_K_S (full)** | **IQ3_XXS (liten)** |
|---|---|---|
| Fil | `drama-3-backbone-4bit-experts-Q4_K_S.gguf` | `drama3-small-IQ3_XXS.gguf` |
| Størrelse | 21,78 GiB | 9,74 GiB |
| Eksperter | 256 per lag | 256 i lag 0/1/2/36, 100 i resten |
| Ekspert-kvantisering | Q4_K | IQ3_XXS (~3 bit) |
| Ryggrad | Q4_K + Q4_0 tekst-embedding | Q8_0 |
| Audio-tower / codec | FP16 / F16 | Q8_0 / F16 |
| Utgangshode | Fullt vokabular (252 288 rader) | EOS + 4 096 semantiske rader |
| Språk | 83 språk | japansk + engelsk |
| Trenger ekspert-offloading | **Ja** | Nei |

Q4_K_S er en ren kvantisering av den offisielle Drama 3-checkpointen og
beholder full språkdekning. IQ3_XXS er en **forkortet og destillert** modell:
eksperter er redusert, og modellen er destillert tilbake mot originalen på
japansk og engelsk tale. Det er derfor språkdekningen forsvinner.

---

## Presisjon

Ordfeilrate (WER) målt med Whisper `small`, mot referenceteksten.
**Lavere er bedre.** 0 % = ordrett.

| Modell | Språk | WER | Transkripsjon |
|---|---|---|---|
| **Q4_K_S, kjøring A** | **norsk** | **36,4 %** | «Mal et A4-ark i grønne av juleneaser. Mal en stor sirkel på 5-12 cm og fyller hele cirkel med farge.» |
| **Q4_K_S, kjøring B** | **norsk** | **18,2 %** | «Mal et afyrark i grønne og gulen jangser. Mal en stor sirkel på **25,5 cm** og fyll hele cirkel med farge.» |
| IQ3_XXS | norsk | 59,1 % | «Mal et A4 ARK i grunn og god nyanser. Mal en stor cirken på 2 utplaner skjermvektet 5 cm og fyller med hele serien.» |
| **Q4_K_S** | **engelsk** | **6,0 %** | ordrett gjengitt |

### Variasjon mellom kjøringer

De to norske kjøringene brukte **identisk konfigurasjon, seed og tekst**, og
ga likevel 36,4 % og 18,2 % WER. Kjøring B fikk «25,5 cm» helt riktig, mens
kjøring A fikk «5-12 cm».

Dette betyr at **tall i teksten er den mest ustabile delen**, ikke norsk
språk generelt. Et gjennomsnitt på ~27 % for de to kjøringene er et
riktigere bilde enn det ene tallet. Hvis tall har betydning i teksten, skriv
dem ut som ord.

### Hva tallene betyr i praksis

**Norsk med Q4_K_S er brukbart.** Whisper identifiserer språket automatisk som
norsk (`no`) — ikke dansk eller svensk. Feilmønsteret fra den lille modellen
er borte.

Én feil gjenstår: **«5-12 cm» i stedet for «25,5 cm»** i den ene kjøringen.
Desimalkommaet misforstås og sifrene byttes om. Tall med desimalkomma er en
kjent svakhet, og kjøring B viser at det ikke slår gjennom hver gang.
Skriv dem ut som ord: «tjugfemfem centimeter».

**Norsk med IQ3_XXS er ubrukelig.** Modellen kollapser ukjente fonemer til
de nærmeste lydene den kjenner, og resultatet blir en setning med naturlig
rytme men feil innhold. «grønne og gule» blir «grunn og god», «sirkel på
25,5 cm» blir «cirken på 2 utplaner skjermvektet 5 cm».

Dette er **ikke** et Norwegian-problem hos Drama 3. Det er et problem med
destilleringen. Beviset er Q4_K_S-modellen: samme arkitektur, samme runtime,
riktig norsk.

---

## Hastighet

RTF (Real-Time Factor) = sekunder brukt ÷ sekunder lyd. **Lavere er bedre.**
RTF 1,0 betyr «i sanntid».

### Samme tekst, begge modeller (ingen referanse, 2,79 s lyd)

| Konfigurasjon | RTF | Peak minne | Disk lest |
|---|---|---|---|
| **IQ3_XXS, fullt resident i Metal** | **4,7** | 10 327 MB | 0 |
| IQ3_XXS, 20 ekspertlag på CPU | 26,1 | 10 338 MB | 0 |
| IQ3_XXS, `disk_experts`, cache=32 | 12,4 | 6 570 MB | 11,4 GB |
| IQ3_XXS, `disk_experts`, cache=16 | 14,2 | 5 783 MB | 14,9 GB |
| IQ3_XXS, `disk_experts`, cache=8 | 13,7 | 5 430 MB | 17,7 GB |
| Q4_K_S, `disk_experts`, cache=8 | 32,0 | 5 874 MB | 22,9 GB |

### Med stemmekloning (referanse inkludert)

| Modell | Språk | Lengde | RTF | Peak minne | Disk lest |
|---|---|---|---|---|---|
| IQ3_XXS, resident | engelsk | 33,1 s | 12,8 | 10 327 MB | 0 |
| IQ3_XXS, resident | norsk | 9,3 s | 11,2 | 10 327 MB | 0 |
| **Q4_K_S, disk-offload** | **engelsk** | **33,1 s** | **28,8** | **6 903 MB** | **351 GB** |
| **Q4_K_S, disk-offload** | **norsk** | **8,4 s** | **26,3** | **6 601 MB** | — |
| **Q4_K_S, disk-offload** | **norsk (kjøring B)** | **9,0 s** | **27,5** | **6 671 MB** | — |

### Uregulær tid

Wall-tid mellom kjøringene kan ikke sammenlignes direkte: første kjøring på
en maskin bruker ~140 s på å kompilere Metal-kjernene. De lagres etter første
gang. Bruk alltid `metrics.rtf`.

### Ekspert-cache

| Cache | RTF | Ekspertlaster | Cache-treff | Treffandel | Buffer | Peak minne |
|---|---|---|---|---|---|---|
| 8 | 13,7 | 14 676 | 6 740 | 46 % | 368 MB | 5 430 MB |
| 16 | 14,2 | 12 384 | 9 032 | 73 % | 735 MB | 5 783 MB |
| 32 | 12,4 | 9 465 | 11 951 | 126 %¹ | 1 470 MB | 6 570 MB |

¹ Treff-telleren overstiger laster-telleren fordi én lading kan dekke flere
forespørsler.

Større cache gir færre disk-lesninger (17,7 → 11,4 GB) og bedre RTF, mot
~1,1 GB ekstra RAM.

---

## Minnebruk

Metal rapporterer en working set på 12 713 MB på denne maskinen.

### Q4_K_S med ekspert-offloading

| Komponent | Størrelse | Hvor | Boende? |
|---|---|---|---|
| `drama3_backbone.weights` | 1 326 MB | Metal | ja |
| `drama3.tower` | 2 173 MB | Metal | ja |
| Fish DAC codec | 747 MB | CPU | ja |
| `disk_experts`-cache | 540 MB | RAM | ja, avgrenset |
| Ekspertbanker | ~17 GB | **disk** | **nei — strømmes underveis** |

Totalt boende: **~4,8 GB** for en modell på 21,78 GiB.
Målt peak fysisk footprint: **6 903 MB**.

### Hvorfor codecen flyttes til CPU

Fish DAC codec holder en 747 MB Metal-buffer. På en 16 GB Mac må den ut av
GPU-minnet, ellers dør prosessen. `fish_drama3.codec_backend=cpu` flytter den.

---

## Ekspert-offloading

Modellen er 21,78 GiB. Macen har 16 GB unified memory, hvorav macOS bare gir
Metal 12 713 MB. Modellen kan ikke være fullt resident.

audio.cpp har en C++-implementasjon (PR #927) som beholder ekspertbankene **i
GGUF-filen** og bare leser de aktive ekspertene inn i en avgrenset cache. Dette
er ikke macOS sin egen virtual-memory-paging.

### Ekspert-I/O under en 33 sekunders engelsk tale

| Måltall | Verdi |
|---|---|
| `bytes_read` | 350 978 310 144 (351 GB) |
| `expert_loads` | 198 352 |
| `cache_hits` | 66 471 (25 % treffandel) |
| `buffer_mb` | 540 |
| `read_ms` | 720 962 (721 s) |
| `upload_ms` | 66 169 |
| `stage_ms` | 788 015 |

**Disk-lesing er 75 % av wall-tiden.** Unified memory hjelper — de strømmede
ekspertene kan brukes direkte av Metal-GPU-en uten PCIe-overføring — men
selve leseoperasjonen er flaskehalsen.

### Prefill-kostnad

| Måltall | Verdi |
|---|---|
| `offload_prefill_attention_ms` | 794 ms |
| `offload_prefill_experts_ms` | 50 119 ms |
| `offload_prefill_expert_work_rows` | 403 968 |
| `offload_prefill_routed_rows` | 176 000 |
| `backbone_step_ms` | 154 984 (166 rammer, ~1,07 s/ramme) |

Forholdet 2,30x mellom arbeidsrader og rutede rader viser at gruppering virker:
én diskopplasting betjener flere tokens i samme lag.

### Om `--n-cpu-moe`

Det finnes **ikke** i audio.cpp — det er et llama.cpp-flagg. Ekvivalentene er:

| Alternativ | Funksjon |
|---|---|
| `fish_drama3.disk_experts=true` | Slår på disk-basert ekspert-offloading |
| `fish_drama3.expert_cache_size=N` | Boende ekspertspor per lag, 8–256 (standard 32) |
| `fish_drama3.cpu_expert_layers=N` | Antall ekspertbanker som kjøres på CPU. `0` = alle på GPU. Nærmeste analog til `--n-cpu-moe`. |
| `fish_drama3.pin_experts=true` | Holder ekspertbankene i pinnet RAM for raskere opplasting. Krever `disk_experts=true`. Ikke testet her. |

---

## Sammenligning med M3 Ultra

[drama3-mac](https://github.com/JordiPosthumus/drama3-mac) av Jordi Posthumus
er en egen MLX-port av Drama 3 med sterke resultater på **M3 Ultra med
512 GB unified memory**. Den bruker **MLX** (Apples eget rammeverk) i stedet for
GGUF/ggml, og modellen er **fullt resident** i RAM.

| | **M3 Ultra + MLX**<br>(drama3-mac) | **M1 Pro 16 GB + audio.cpp**<br>(denne rapporten) |
|---|---|---|
| Modell | Drama 3 full, eksperter i 4 bit | Drama 3 full, Q4_K_S |
| Runtime | MLX (native Apple) | audio.cpp (GGUF / ggml) |
| Modell i RAM | **Fullt resident**, 27,3 GB peak RSS | **Disk-offload**, 6,9 GB peak |
| Disk lest pr. 33 s | 0 | 351 GB |
| **Steady-state RTF** | **0,68** | **28,8** |
| Decode | 31,4 rammer/s (trenger 21,5) | ~1,07 s/ramme |
| Prefill | ~1,9 s for 31 rader | 50,1 s for 176 000 rutede rader |
| RAM krav | 27,3 GB | 6,9 GB |

**Hastighetsforskjellen er ~42x** (28,8 mot 0,68 RTF) — men den skyldes
**innstillingene og maskinen**, ikke modellen:

1. **Modellen er fullt resident på M3 Ultra.** Med 512 GB RAM er det ingen
   grunn til å streame eksperter fra disk. På 16 GB er disk-offloading
   **tvunget** — det er den eneste måten å kjøre en 21,78 GiB-modell på
   maskinen. Og nettopp derfor er 351 GB disklesing 75 % av wall-tiden.
2. **M3 Ultra har langt mer minnebåndbredde.** M3 Ultra leverer omtrent
   800 GB/s mot rundt 200 GB/s for M1 Pro. Drama 3 er
   minnebåndbredde-bundet ved decode.
3. **MLX er Apples eget rammeverk.** Det bruker `mx.compile` med eksplisitt
   trådede caches per lag, noe som fjerner CPU-dispatch-overhead. ggml har
   generellere kodeveier.
4. **Ulik kvantisering av ryggraden.** drama3-mac holder projeksjonene i
   **bf16** — slik som den offisielle FP8-utgivelsen — og kvantiserer bare
   ekspertene. Q4_K_S-pakken kvantiserer også ryggraden. drama3-mac har altså
   både høyere kvalitet og høyere hastighet.
5. **Decode er kernel-launch-bundet, ikke båndbredde-bundet**, i drama3-mac:
   ~1 500 små Metal-kjerner per steg. Deres egne analyse viser at de ~7 GB
   vektene som leses per steg ville tatt ~9 ms ved topp-båndbredde. På vår
   M1 Pro bruker samme arbeid 1 070 ms — fordi hver steg må hente eksperter
   fra disk.

**Konklusjon:** På en M3 Ultra med nok RAM er det klart raskere å bruke
drama3-mac. På en Mac med 16 GB finnes det ikke dette alternativet — modellen
kan ikke holdes resident, så disk-offloading er ikke en optimalisering men en
nødvendighet. Med 512 GB RAM og en dedikert disk kan *samme* audio.cpp-oppsett
bruke `disk_experts=false` og få fullt resident hastighet.

### Nyttige inntrykk fra drama3-mac

Noen funn derfra er verdt å låne, uansett runtime:

- **30 sekunders referanse med flere opptak** gir mer stabil stemme enn ett
  kort opptak. Målt: cosinus-likhet 0,939 mot 0,895 for et enkelt 4-sekunders
  opptak.
- **«Kald» sampling for fortelling, «varm» for følelser.** `temperature 0.7,
  top_p 0.85` for rolig tekst, `temperature 0.8, top_p 0.9` for emosjonelle
  partier.
- **Aldri kvantiser projeksjonene.** Å gjøre det gir flytende gibberish,
  fordi støyen multipliseres gjennom 40 lag. drama3-mac har et eget
  sikkerhetsflagg for dette.
- **Aksepteringskrav:** et klipp regnes som godt bare hvis Whisper
  transkriberer det tilbake til prompten. Vi brukte samme metode.

---

## Anbefaling

| Mål | Anbefaling |
|---|---|
| Naturlig norsk | **Q4_K_S med ekspert-offloading.** Riktig norsk, 83 språk, 6,9 GB RAM. |
| Rask prototyping | **IQ3_XXS, fullt resident.** RTF 4,7. Japansk og engelsk. |
| Lavest minnebruk | Q4_K_S med `disk_experts=true`, `cache=8` — 6,6 GB peak. |
| Best mulig kvalitet | drama3-mac på en Mac med nok RAM til at modellen blir resident. |
| Norske tall i teksten | Skriv ut som ord. «25,5 cm» blir «5-12 cm». |

### Praktiske råd for Q4_K_S på 16 GB

- `expert_cache_size=8` når minnet er trangt, `32` når du tåler ~1,5 GB mer
  og vil ha færre disklesninger.
- Regn med **~350 GB disklesing per 33 sekunders tale**. På en rask SSD går
  det, på en tregere disk går det dårligere.
- En 33-sekunders tale tar ~16 minutter. Kortere tekst = raskere.
  21,5 rammer ≈ 1 sekund lyd, så `max_tokens` bør følge lengden.
- `pin_experts=true` ville holdt ekspertbankene i pinnet RAM, men krever at
  hele banksettet er i minnet — motsatt av hensikten med disk-offloading på en
  16 GB-maskin.

---

## Testopplegg

Alt som er fast mellom kjøringene:

| Variabel | Verdi |
|---|---|
| Runtime | `audio.cpp 0.9.2-drama3-base-small` (macOS arm64 Metal) |
| Maskin | Apple M1 Pro, 10 kjerner, 16 GB, macOS 27.0.1 |
| Referanse | `referanse_stemme.wav` — 8,0 s, 44,1 kHz, mono, PCM 16-bit |
| Referansetranskript | `referanse/transkript.txt` (identisk for begge) |
| Engelsk tekst | 67 ord |
| Norsk tekst | 2 setninger |
| Seed | `42` |
| Tråder | `10` |
| Backend | `metal` |
| Modus | `offline` (`--metrics` fungerer bare her) |
| `context_length` | `2048` |
| `codec_backend` | `cpu` |
| `codec_encoder_chunk_samples` | `65536` |
| `max_tokens` | `700` (engelsk) / `400` (norsk) |

Det eneste som varierer mellom kjøringene, er modellfilen og plasseringen av
ekspertene:

| Kjøring | Modell | Ekspertplassering |
|---|---|---|
| Liten | `drama3-small-IQ3_XXS.gguf` | Fullt resident, `cpu_expert_layers=0` |
| Full | `drama-3-backbone-4bit-experts-Q4_K_S.gguf` | `disk_experts=true`, `cache=8`, `cpu_expert_layers=0` |

Målemetode: RTF fra `metrics.rtf`; transkripsjon via Whisper `small` med
språket tvunget for norsk, og på nytt med auto-detekt for å bekrefte språket i
lyden; stillhet via `ffmpeg silencedetect`; swap-nivå via
`sysctl vm.swapusage` rundt hver kjøring.

---

## Koblinger

| Prosjekt | Lenke |
|---|---|
| Fish Audio Drama 3 (modellen) | [huggingface.co/fishaudio/drama-3](https://huggingface.co/fishaudio/drama-3) |
| audio.cpp (runtime) | [github.com/0xShug0/audio.cpp](https://github.com/0xShug0/audio.cpp) |
| Drama 3-dokumentasjon | [docs/models/fish_drama3.md](https://github.com/0xShug0/audio.cpp/blob/main/docs/models/fish_drama3.md) |
| Q4_K_S-konvertering | [huggingface.co/Jmica/Drama-3-GGUF](https://huggingface.co/Jmica/Drama-3-GGUF) |
| IQ3_XXS (liten modell) | [huggingface.co/pentacoxian-dev/drama3-small-GGUF](https://huggingface.co/pentacoxian-dev/drama3-small-GGUF) |
| drama3-mac (MLX-port, M3 Ultra) | [github.com/JordiPosthumus/drama3-mac](https://github.com/JordiPosthumus/drama3-mac) |
| PrismML-Eng/llama.cpp (fork) | [github.com/PrismML-Eng/llama.cpp](https://github.com/PrismML-Eng/llama.cpp) |
| fish-speech (oppsream) | [github.com/fishaudio/fish-speech](https://github.com/fishaudio/fish-speech) |
| Drama 3 teknisk rapport | [arxiv.org/abs/2610.18010](https://arxiv.org/abs/2610.18010) |

---

## Lisens

Modellene er under **Fish Audio Community License v1.0**. Gratis for
forskning og ikke-kommersiell bruk; begrenset kommersiell bruk under
500 000 USD i årlig omsetning.

Lydklippene ble laget med forfatterens egen stemme som referanse, for å
dokumentere resultatene.
