# Rojo-opsætning (dansk guide)

Denne guide hjælper dig med at koble din kode sammen med Roblox Studio.
Tag ét trin ad gangen. Du behøver ikke forstå det hele med det samme. 🙂

---

## Hvad er Rojo? (kort og enkelt)

- Din kode bor i mapper på din computer (og på GitHub).
- Roblox Studio kan IKKE læse de mapper af sig selv.
- **Rojo er broen.** Den sender koden fra mapperne ind i Studio — live.
- Når jeg (Claude) skriver kode, lægger jeg den i mapperne. Rojo sender den videre til dit spil.

Billede i hovedet:

    Mine filer  →  Rojo (broen)  →  dit spil i Roblox Studio

---

## Det skal du installere ÉN gang

Du skal installere 2 ting på DIN computer:

1. **Rojo-plugin'et inde i Roblox Studio** (knappen, der siger "Connect").
2. **Rojo-programmet på computeren** (motoren, der sender koden).

Følg trinene længere nede.

---

## Trin 1 — Hent projektet ned på din computer

Koden ligger på GitHub. Du skal have den ned på din egen computer.

Nemmeste måde for begyndere: **GitHub Desktop**.

1. Gå til https://desktop.github.com og hent GitHub Desktop.
2. Installer og log ind med din GitHub-konto.
3. Klik **File → Clone repository**.
4. Vælg `giffelbiffel/giffelbiffel`.
5. Klik **Clone**.

Nu ligger projektet i en mappe på din computer. Husk hvor (GitHub Desktop viser stien).

---

## Trin 2 — Installer Rojo-plugin'et i Roblox Studio

1. Åbn Roblox Studio.
2. Klik på fanen **Plugins** øverst.
3. Klik på **Find Plugins** (eller Plugin-marketplace).
4. Søg efter **Rojo**.
5. Klik **Install** på pluginnet, der hedder *Rojo* (af Roblox-brugeren `rojo`).
6. Nu har du en lille **Rojo**-knap i Plugins-fanen.

---

## Trin 3 — Installer Rojo-programmet på computeren

Den nemmeste vej er via **Visual Studio Code** (en gratis kode-editor):

1. Hent VS Code: https://code.visualstudio.com
2. Åbn VS Code → klik på "Extensions"-ikonet i venstre side (firkanterne).
3. Søg efter **Rojo** (lavet af `evaera`).
4. Klik **Install**.
5. Åbn din projektmappe i VS Code: **File → Open Folder** → vælg `giffelbiffel`-mappen fra Trin 1.

VS Code-udvidelsen henter selv Rojo-programmet for dig. Nemt. 👍

---

## Trin 4 — Start Rojo (broen)

1. I VS Code: tryk **Ctrl + Shift + P** (åbner kommando-feltet).
2. Skriv **Rojo: Start server** og tryk Enter.
3. Vælg `default.project.json`, hvis den spørger.
4. Rojo kører nu. Lad VS Code stå åben.

---

## Trin 5 — Forbind Studio til Rojo

1. Gå tilbage til Roblox Studio.
2. Klik på **Rojo**-knappen i Plugins-fanen.
3. Klik **Connect**.
4. Hvis det lykkes, står der "Connected". 🎉

---

## Trin 6 — Tjek at det virker

1. Kig i **Output**-vinduet i Studio (View → Output, hvis det ikke er åbent).
2. Tryk **Play** (den blå knap øverst).
3. Du bør se teksten:

   `Hej fra Rojo! Din kode blev sendt ind i spillet. 🚀`

Hvis du ser den — så er ALT sat rigtigt op. Godt arbejde! 🥳

---

## Sådan arbejder vi sammen fremover

1. Du beder mig (Claude) om en funktion, fx "lav penge for at dræbe zombier".
2. Jeg skriver koden og lægger den på GitHub.
3. Du åbner GitHub Desktop og klikker **Pull** (henter den nye kode).
4. Rojo sender den automatisk ind i dit spil.
5. Du trykker Play og tester.

---

## Mapperne i projektet (hvad er hvad)

- `src/server/`  → kode, der kører på serveren (fx penge, zombier, regler).
- `src/client/`  → kode, der kører hos hver spiller (fx knapper, menuer).
- `src/shared/`  → kode, begge kan bruge (fx fælles tal og indstillinger).

Filnavne fortæller Roblox, hvad det er:
- `noget.server.luau`  → et Script (server).
- `noget.client.luau`  → et LocalScript (spiller).
- `noget.luau`         → et ModuleScript (deles).

---

## Hvis noget går galt

- **"Connect" virker ikke?** Tjek at Rojo-serveren kører i VS Code (Trin 4).
- **Ingen tekst i Output?** Tjek at du trykkede Play, og at du er Connected.
- Skriv til mig, hvad der står, så hjælper jeg. Du kan ikke ødelægge noget. 🙂
