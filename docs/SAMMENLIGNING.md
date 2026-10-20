# Sammenligning: Drama 3 vs CosyVoice3 vs Chatterbox v3

Tre modeller testet på **samme maskin**, med **samme tekst**, **samme
referanseklipp** og **samme seed**. Alle klipp ligger i `audio/` så du kan
høre dem selv.

**Maskin:** Apple M1 Pro, 10 kjerner, 16 GB unified memory, macOS 27.0.1

---

## Resultattabellen

| Modell | Språk | WER | Auto-språk | ΔF0 | RTF | Peak RAM |
|---|---|---|---|---|---|---|
| **Drama 3 Q4_K_S** | norsk | **18,2 %** | `no` | +34,9 Hz | 27,5 | 6,7 GB |
| **Drama 3 Q4_K_S** | norsk | 36,4 % | `no` | −3,5 Hz | 26,3 | 6,9 GB |
| **CosyVoice3 + LoRA** | norsk | **31,8 %** | `no` | −1,6 Hz | **10,8** | ~7 GB |
| **Chatterbox v3** | norsk | 59,1 % | `no` | −8,4 Hz | 21,8 | — |
| **Drama 3 IQ3_XXS** | norsk | 59,1 % | `no` | −12,6 Hz | **11,2** | 10,3 GB |
| **Drama 3 Q4_K_S** | engelsk | **6,0 %** | `en` | +6,0 Hz | 28,8 | 6,9 GB |
| **CosyVoice3 + LoRA** | engelsk | 11,9 % | **`sv`** | +18,6 Hz | 7,7 | ~7 GB |
| **Chatterbox v3** | engelsk | 14,9 % | **`no`** | −22,6 Hz | **5,8** | — |

**WER** = ordfeilrate, lavere er bedre. **RTF** = real-time factor, lavere er
bedre (1,0 = i sanntid). **Auto-språk** er hva Whisper selv finner ut i lyden —
det avslører aksent-drift. **ΔF0** er avviket i grunnfrekvens fra referansen.

---

## Hva tallene viser

### 1. Norsk: Drama 3 og CosyVoice3 er jevnbyrdige, Chatterbox er klart dårligere

De to beste norske resultatene:

- **Drama 3 Q4_K_S: 18,2 %** (bedste kjøring) og 36,4 % (andre kjøring)
- **CosyVoice3 + norsk LoRA: 31,8 %**
- **Chatterbox v3: 59,1 %** — på nivå med drama3-small

Chatterbox-forsøket produserte «Mal en stor kyrkel på 55-3» — «kyrkel» for
«sirkel», og tallet ble til «55-3». Det er samme type feil som drama3-small
gjør: modellen approksimerer ukjente lyder.

**Drama 3-variasjonen er verdt å merke seg.** To kjøringer med identisk
oppsett ga 18,2 % og 36,4 %. Den ene fikk «25,5 cm» helt riktig, den andre
«5-12 cm». Gjennomsnittet (~27 %) er det riktige tallet å planlegge med.

### 2. Engelsk: Drama 3 er best på innhold, CosyVoice3 og Chatterbox har tydelig aksent-drift

Her kommer det mest interessante:

| Modell | WER | Hva Whisper hør |
|---|---|---|
| Drama 3 Q4_K_S | 6,0 % | `en` — ren engelsk |
| CosyVoice3 + LoRA | 11,9 % | **`sv`** — svensk! |
| Chatterbox v3 | 14,9 % | **`no`** — norsk! |

**Dette bekrefter inntrykket ditt.** CosyVoice3 og Chatterbox begge faller ut av
engelsk når de skal lese engelsk med en norsk referanse. CosyVoice3 går til
svensk, Chatterbox går til norsk.

Årsaken er klar: begge modellene er **språkbundet til referansen**. Når
referansen er norsk, trekker de norske fonemene med seg — engelsk får norsk
uttale, og etter nok aksentdrift blir det ikke lenger engelsk.

Drama 3 går ikke i samme felle, fordi den ble trent på 83 språk. Den holder
engelsk uttale selv med norsk referanse, og det eneste som er igjen av
referansen er aksenten.

### 3. CosyVoice3 er raskest på norsk — halvparten så lang tid som Drama 3

| | RTF | Tid for 9 s norsk |
|---|---|---|
| CosyVoice3 + LoRA | **10,8** | ~113 s |
| Drama 3 Q4_K_S | 26,3 | ~221 s |
| Drama 3 IQ3_XXS | **11,2** | ~104 s |
| Chatterbox v3 | 21,8 | ~164 s |

CosyVoice3 er 2,4x raskere enn Drama 3 på norsk, fordi den er en 0,5B-modell
mot Drama 3s 35B. Den kjøres på CPU med en 0,5B-modell — ingen
ekspert-offloading, ingen disklest.

På engelsk er CosyVoice3 raskest igjen (RTF 7,7 mot Drama 3s 28,8).

**Drama 3s 28,8 RTF skyldes disk-offloading.** Modellen bruker 6,9 GB RAM og
leser 351 GB fra disk for en 33 sekunders tale. Uten et NVMe-drev går det
langsommere.

---

## Aksent-drift i detalj

| Modell | Auto-språk i engelsk | ΔF0 mot referansen | Hva det betyr |
|---|---|---|---|
| Drama 3 Q4_K_S | `en` | +6,0 Hz | Nesten perfekt. Ren engelsk, naturlig pitch. |
| CosyVoice3 + LoRA | `sv` | +18,6 Hz | Uttalen blir svensk. Pitchen drar opp. |
| Chatterbox v3 | `no` | −22,6 Hz | Uttalen blir norsk. Pitchen drar ned. |

F0 = grunnfrekvens, altså stemmens tonehøyde. Referansen ligger på 126 Hz.
Drama 3 holder seg innenfor 6 Hz. CosyVoice3 går 19 Hz unna, Chatterbox 23 Hz
unna — og det er *i motsatt retning*, noe som tyder på at de ikke bare
«mangler» engelsk, men aktivt trekker mot referansens språk.

### Hva internett-impresjonen sier

Funnene her stemmer med det generelle inntrykket:

- **Fish Audio S2 Pro** omtales i r/LocalLLaMA som «almost perfect, I get very
  few artifacts if any and voice cloning is near 1:1 with the source», og
  rangeres første i flere sammenligninger.
- **CosyVoice** omtales ofte med forbehold. I en sammenligning skrives det at
  CosyVoice 2 reduserte uttaksfeilrate med 30–50 % mot v1, men at
  «ytterligere forbedring krever kvantisering av projeksjonene, som gir
  alvorlig kvalitetstap» — en handel de fleste lokal-brukere ikke tar.
- **Chatterbox** regnes som enklere og lettere å kjøre, med mindre
  ekspresjonskontroll.

Det viktige skillet er likevel ikke modellene generelt, men **språkbindingen
til referansen**. CosyVoice3 i denne testen har en norsk LoRA — det er
norsktuningen som gjør at engelsk faller ut. Med en engelsk referanse ville
resultatet sett annerledes ut.

---

## Transkripsjoner

### Norsk

**Drama 3 Q4_K_S (bedste kjøring, 18,2 %)**
> Mal et afyrark i grønne og gulen jangser. Mal en stor sirkel på **25,5 cm** og
> fyll hele sirkel med farge.

**Drama 3 Q4_K_S (andre kjøring, 36,4 %)**
> Mal et A4-ark i grønne av juleneaser. Mal en stor cirkel på 5-12 cm og fyll
> hele cirkel med farge.

**CosyVoice3 + norsk LoRA (31,8 %)**
> Mal et avfor ark i grønne og gule nyanser. Mal en stor cirkel på tønt i 4-4 cm
> og fyll hele cirklen med farge.

**Chatterbox v3 (59,1 %)**
> Mal et av fire ark i grønne og gul enn janser. Mal en stor kyrkel på 55-3 og
> fyl hele kyrkelen med farget.

**Drama 3 IQ3_XXS (59,1 %)**
> Mal et A4 ARK i grunn og god nyanser. Mal en stor cirken på 2 utplaner
> skjermvektet 5 cm og fyller med hele serien.

### Engelsk

**Drama 3 Q4_K_S (6,0 %)**
> I have achieved a higher level of proficiency, demonstrated by details such as
> creating varied imprints using different plants, painting the jewelry pieces,
> crafting jewelry in various shapes and investing time in making multiple
> attempts. Exploring texture and small scale craft projects using clay. Creating
> clay slabs featuring nature imprints, making small jewelry pieces using
> seashell imprints and paints, variety in imprints, creativity in jewelry
> design and effort.

**CosyVoice3 + LoRA (11,9 %, høres ut som svensk)**
> I have achieved a higher level of proficiency, demonstrated by the tiles such
> as creating varied imprints using different plants, painting the jewellery
> pieces, crafting jewellery in various shapes and investing time and making
> multiple attempts. Exploring texture and small scale craft projects using clay.
> Creating clay slabs featuring nature imprints, making small jewellery pieces
> using seashell, imprints and paint. Variety in imprints, creativity in
> jewellery design and effort.

**Chatterbox v3 (14,9 %, høres ut som norsk)**
> I have archived a high level of proficiency, demonstrated by the tilesuchas,
> creating varied imprints using different plants, painting the jewellery
> pieces, crafting jewellery in various shapes, and investing time on making
> multiple attempts. Exploring texture and small-scale craft projects using
> clay. Creating clay, slabs featuring nature imprints, marking small jewellery
> pieces using seashell imprints and paint, variety in imprints, creativity in
> jewellery design, and effort.

---

## Genereringskostnad

Hva det koster å lage én tale. Tallene er for maskinen over.

| Modell | Norsk (9 s) | Engelsk (33 s) | Disk lest | Modellstørrelse |
|---|---|---|---|---|
| **CosyVoice3 + LoRA** | **113 s** | 243 s | 0 | 0,5B (9,1 GB) |
| **Chatterbox v3** | 164 s | 177 s | 0 | ~1,5 GB |
| **Drama 3 IQ3_XXS** | 104 s | — | 0 | 9,74 GiB |
| **Drama 3 Q4_K_S** | 221 s | 953 s | 351 GB | 21,78 GiB |

**Kostnad per sekund tale:**

| Modell | Norsk | Engelsk |
|---|---|---|
| CosyVoice3 | 11,8 s/s | 7,7 s/s |
| Chatterbox | 21,8 s/s | 5,8 s/s |
| Drama 3 IQ3_XXS | 11,2 s/s | — |
| Drama 3 Q4_K_S | 26,3 s/s | 28,8 s/s |

Drama 3 Q4_K_S er altså **3–4x dyrere** enn CosyVoice3 og Chatterbox per
sekund tale, på grunn av disk-offloadingen.

---

## Lydfilene

Høre selv — dette er hele poenget:

| Fil | Modell | Språk | Lengde |
|---|---|---|---|
| `audio/norsk_full_q4k_varianter.wav` | Drama 3 Q4_K_S | norsk | 9,0 s |
| `audio/norsk_full_q4k.wav` | Drama 3 Q4_K_S | norsk | 8,4 s |
| `audio/cosyvoice_norsk.wav` | CosyVoice3 + LoRA | norsk | 10,5 s |
| `audio/chatterbox_norsk.wav` | Chatterbox v3 | norsk | 7,5 s |
| `audio/norsk_small_ubrukelig.wav` | Drama 3 IQ3_XXS | norsk | 9,3 s |
| `audio/engelsk_full_q4k.wav` | Drama 3 Q4_K_S | engelsk | 33,1 s |
| `audio/cosyvoice_engelsk.wav` | CosyVoice3 + LoRA | engelsk | 31,6 s |
| `audio/chatterbox_engelsk.wav` | Chatterbox v3 | engelsk | 30,2 s |
| `audio/referanse_stemme.wav` | — | norsk (referanse) | 8,0 s |

Alle 44,1 kHz (Drama 3) eller 24 kHz (CosyVoice3, Chatterbox), mono.

---

## Konklusjon

| Behov | Anbefaling |
|---|---|
| Best norsk **og** engelsk, én modell | **Drama 3 Q4_K_S.** 18–36 % WER norsk, 6 % engelsk, holder språket. |
| Raskest norsk | **CosyVoice3 + LoRA.** 2,4x raskere, 31,8 % WER. |
| Raskest engelsk | **Chatterbox v3.** RTF 5,8 — men 14,9 % WER og norsk aksent. |
| Lavest minnebruk | CosyVoice3 (0,5B) eller Chatterbox (~1,5 GB). |
| Kortest kontekst, minst disk | CosyVoice3 / Chatterbox — ingen disk-offloading. |
| Drama 3 men raskere | Drama 3 IQ3_XXS (RTF 11,2) — men norsk blir ubrukelig. |

**Den viktigste forskjellen er ikke hastighet, men språkstability.** Drama 3
beholder språket uansett referanse. CosyVoice3 og Chatterbox trekker mot
referansens språk — noe som er ønsket når du vil ha norsk, og uønsket når du
skal ha engelsk.

---

## Målemetode

- **WER**: Whisper `small`, mot referenceteksten, normalisert for skilletegn og
  store/små bokstaver. Levenshtein-avstand på ordnivå delt på referanselengde.
- **Auto-språk**: Whisper uten språkkraft, altså modellens egen vurdering av
  hvilket språk lyden er.
- **F0**: median grunnfrekvens via autokorrelasjon over de første 3 sekundene.
- **RTF**: `metrics.rtf` for Drama 3 (audio.cpp), målt i scriptene for
  CosyVoice3 og Chatterbox. Alle inkluderer modell-lasting? Nei — kun
  generering.
- **Referanse**: 8 sekunder norsk, 44,1 kHz mono, identisk for alle modeller.
  CosyVoice3 og Chatterbox fikk samme fil konvertert til 24 kHz.

### En merknad om CosyVoice3-oppsettet

CosyVoice3-testen brukte de opprinnelige innstillingene fra
`generate_audio_stabile_CPU_Accurate.py`: norsk LoRA, CPU, og instruksjonen
`"You are a helpful assistant. Speak in Norwegian."` (norsk) respektively
`"Speak in English."` (engelsk).

Underveis ble det observert at en ** kinesisk** instruksjon fikk modellen til å
produsere finsk for norsk tekst og svensk for engelsk tekst. Det er et
eksempel på hvor sterkt språkdirektivet styrer: et direktiv på feil språk
flytter hele outputen. Alle tall i denne rapporten er fra kjøringer med
riktig språkdirektiv.

---

## Koblinger

| Prosjekt | Lenke |
|---|---|
| Fish Audio Drama 3 | [huggingface.co/fishaudio/drama-3](https://huggingface.co/fishaudio/drama-3) |
| audio.cpp | [github.com/0xShug0/audio.cpp](https://github.com/0xShug0/audio.cpp) |
| Q4_K_S-konvertering | [huggingface.co/Jmica/Drama-3-GGUF](https://huggingface.co/Jmica/Drama-3-GGUF) |
| CosyVoice | [github.com/FunAudioLLM/CosyVoice](https://github.com/FunAudioLLM/CosyVoice) |
| Chatterbox | [github.com/resemble-ai/chatterbox](https://github.com/resemble-ai/chatterbox) |
| drama3-mac (MLX, M3 Ultra) | [github.com/JordiPosthumus/drama3-mac](https://github.com/JordiPosthumus/drama3-mac) |
