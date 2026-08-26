# Schnellstart

Von null zur laufenden App. Rechne mit **20–30 Minuten** beim ersten Mal, danach mit fünf.

> Diese Anleitung ist für Dich. Alle anderen Dateien im Repo sind für den Agenten —
> Du musst sie nicht lesen, aber Du darfst.

---

## Vorher klären (nicht am Workshop-Morgen)

**Windows?** Rails läuft nicht direkt unter Windows, Du brauchst WSL2. In PowerShell **als Administrator**:

```
wsl --install
```

Danach neu starten und ab hier alles in der „Ubuntu"-App machen. **Das braucht Administratorrechte** — wenn Deine IT die nicht rausgibt, klär das vorher. Am Morgen ist es zu spät.

**Mac oder Linux?** Nichts vorzubereiten.

**GitHub-Konto** brauchst Du, um an den Harness zu kommen.

---

## Schritt 1 — Projektordner anlegen

Der Harness liegt **nicht neben** Deinem Projekt — er **ist** Dein Projekt. Alles wächst in diesem einen Ordner.

Leg Dir irgendwo einen Sammelordner an, z. B. `MeinCode`. Darin bekommt jedes Projekt einen eigenen Unterordner:

```
MeinCode/
  ticket-tool/          ← der Harness, umbenannt auf Deinen Projektnamen
  naechstes-projekt/    ← ein zweites Projekt = eine zweite Kopie
```

So kommst Du an den Harness — einer der drei Wege:

1. **Im Workshop:** Nenn Deinen GitHub-Namen, Du bekommst eine Einladung ins Harness-Repo. Claude legt Dir den Inhalt in Deinen Projektordner.
2. **Selbst:** Auf GitHub den Knopf **„Use this template"** → eigenes Repo → in Deinen Sammelordner klonen.
3. **Notnagel:** ZIP herunterladen, entpacken, Ordner umbenennen. Funktioniert, aber ohne Git.

Wenn es geklappt hat, liegen in Deinem Projektordner unter anderem `CLAUDE.md`, `requirements.md`, `design-system.md` und ein Ordner `.claude`.

---

## Schritt 2 — Claude **in diesem Ordner** öffnen

Das ist der häufigste Fehler des ganzen Tages. Öffnest Du eine Ebene höher (im Sammelordner), werden die Projektdateien nicht gefunden und keiner der Befehle unten existiert.

**In der Claude-Desktop-App:** Reiter **Code** → Umgebung **Local** (unter Windows: **WSL**) → **Select folder** → Deinen Projektordner wählen.

**Im Terminal:** in den Projektordner wechseln, dann `claude` starten.

Beides ist dasselbe Programm und arbeitet mit denselben Projektdateien — App und Terminal teilen sich `CLAUDE.md`, die Skills, Hooks und Einstellungen. Du kannst sogar beide gleichzeitig offen haben.

Prüfen: Tipp `/` (oder **+** → *Slash commands*) — wenn `/init-project` in der Liste auftaucht, bist Du richtig.

---

## Schritt 3 — Rechner einrichten (einmalig)

```
/init-dependencies
```

Installiert Ruby und alles Weitere. Dauert beim ersten Mal ein paar Minuten.

⚠️ **Danach die Unterhaltung schließen und eine neue starten.** Sonst findet Claude das frisch installierte Ruby nicht. Das ist kein Fehler, das muss so.

Du machst das **einmal pro Rechner**, nicht pro Projekt.

---

## Schritt 4 — Projekt aufsetzen

```
/init-project "ein Ticket-Tool für kleine Bühnen"
```

Ein Satz genügt. Claude baut daraus die komplette App: Datenbank, Anmeldung, Tests, Design-Grundlage.

Danach startest Du den Server:

```
bin/dev
```

Im Browser `http://localhost:3000` öffnen — da steht Deine leere App, Du kannst Dich registrieren und anmelden.

### Was es mit dem Server auf sich hat

Deine Anwendung läuft **auf Deinem eigenen Rechner**, nicht im Internet. `bin/dev` ist der Schalter dafür. Vier Dinge, die Du dazu wissen solltest:

- **Er muss laufen, damit Du etwas siehst.** Ist die Seite im Browser leer oder meldet „nicht erreichbar", ist meistens einfach der Server aus.
- **Er läuft weiter, während Du baust.** Du musst ihn nicht bei jeder Änderung neu starten — die meisten Änderungen siehst Du sofort nach dem Neuladen der Seite.
- **Nach Design-Änderungen einmal neu starten.** Mit `Strg+C` beenden, dann wieder `bin/dev`.
- **„Port already in use"** heißt: Er läuft schon, vermutlich in einem anderen Fenster. Entweder dieses benutzen oder dort `Strg+C` drücken.
- **„A server is already running (pid: …)"** ist etwas anderes und passiert, wenn Du das Fenster geschlossen hast, ohne `Strg+C` zu drücken. Der Server ist weg, nur seine Visitenkarte liegt noch da. Sag Claude: **„Lösch die Datei `tmp/pids/server.pid` und starte neu."**

`http://localhost:3000` erreicht **nur Dein Rechner**. Niemand sonst im Raum kann Deine App sehen — zum Zeigen dreht ihr den Bildschirm um. Das genügt für alles, was wir in diesen zwei Tagen tun, auch für die Abschlussdemo.

### Eine zweite Adresse: `http://localhost:3000/design`

**Das ist Dein Baukasten.** Dort stehen alle Bausteine, aus denen Deine App gebaut wird — Knöpfe, Formulare, Meldungen, Tabellen — noch im neutralen Standard. Dreißig Sekunden reinschauen lohnt sich: Es ist genau das, was Euer Corporate Design am zweiten Tag verwandelt.

Neben jeder Farbe steht ihr **Name**. Den brauchst Du später: Statt „mach das mal freundlicher" sagst Du *„brand-600 ist mir zu grell"* — und Claude trifft es sofort.

### Und eine dritte: `http://localhost:3000/flow`

**Dein Hauptweg** — der eine Ablauf, der am Ende funktionieren muss, als Kästen und Pfeile. Jetzt ist die Seite noch leer; im nächsten Schritt füllt Claude sie aus dem, was Du ihm erzählst.

Wenn sie gefüllt ist, ist das die wichtigste Minute des Tages: **Schau hin und sag, wo es falsch ist.** Ein fehlender Schritt fällt hier in Sekunden auf — im Fließtext nicht.

---

## Schritt 5 — Sag, was Du bauen willst

```
/grill
```

**Jetzt kommt Dein wichtigster Beitrag des Tages** — und er besteht aus Reden, nicht aus Tippen.

Claude fängt an, indem er **zuhört**. Er fragt Dich nach der Aufgabe, die Dich in Deiner Woche am meisten nervt, und Du erzählst — zwei, drei Minuten am Stück, den letzten konkreten Fall. Er unterbricht nicht. Danach schreibt er `requirements.md` und liest Dir vor, was er verstanden hat.

**Erst dann wird gefragt.** Eine Frage nach der anderen, jede mit seinem eigenen Vorschlag. Du sagst meistens nur „ja" oder wählst zwischen zwei Möglichkeiten. Nach acht bis zwölf Fragen steht die Anforderung so klar, dass ein Fremder Dein Projekt daraus bauen könnte.

Das fühlt sich nach Zeitverschwendung an. Ist es nicht — es ist die Zeit, die Du am Nachmittag nicht mit Umbauen verbringst.

> **Später nochmal nötig?** Wenn ein Punkt im Bauen nicht trägt, sag `/grill` mit dem Thema dahinter — zum Beispiel `/grill Suche`. Dann schärft er nur das nach, statt von vorn anzufangen.

---

## Schritt 6 — Euer Look (am zweiten Tag, zwei Minuten)

Am Ende von `/grill` fragt Claude, ob die App einem Corporate Design folgen soll. Drei Wege stehen offen — **Website-Adresse**, ein **Markenhandbuch** (Datei in den Projektordner legen) oder eine **Beschreibung in Worten** („Petrol und warmes Grau"). Er merkt sich die Antwort und wendet sie noch nicht an.

**Das ist Absicht.** An einer leeren App fällt ein Farbwechsel kaum auf. Am zweiten Tag, wenn Deine App Inhalt hat, dreht sie sich auf einen Schlag um:

```
/design-system https://eure-firma.de
```

Claude liest Farben, Schrift und Formen, prüft die Lesbarkeit und schreibt Euer Design an genau eine Stelle. Danach `bin/dev` einmal neu starten — und dann **beide Seiten neu laden**, Deine App und `http://localhost:3000/design`. Dort siehst Du auf einen Blick, was sich verändert hat.

Willst Du etwas nachschärfen: Nimm den Namen von der Design-Seite. *„brand-600 ist mir zu grell"* — Claude ändert einen Wert, und die ganze App zieht nach.

Überspringst Du es, bleibt es beim neutralen Standard — auch gut.

---

## Schritt 7 — Planen, dann bauen

**Ab hier keine Befehle mehr — nur noch Sätze.** Die beiden unten stehen zwar wie Kommandos da, sind aber ganz normale Sätze im Chat. Du musst sie nicht wörtlich treffen; sag es in Deinen Worten, wenn Dir andere lieber sind.

```
Stell mir einen Plan vor.
```

Claude legt Reihenfolge, Risiken und Annahmen vor. **Lies ihn wirklich.** Hier ist Korrigieren billig, im Code teuer.

Wenn der Plan steht:

```
Jetzt bau.
```

Ab hier arbeitet die Maschine weitgehend allein. Musst Du ständig eingreifen, war der Plan noch nicht fertig.

> **Vor der Demo: Beispieldaten.** Eine leere Anwendung sieht nach nichts aus, egal wie gut sie ist. Sag am zweiten Tag: **„Füll mir zehn glaubwürdige Beispieleinträge ein."** Das dauert zwei Minuten und entscheidet, ob Du Formulare zeigst oder ein Produkt.

---

## Schritt 8 — Veröffentlichen? Diesmal nicht

In diesem Workshop bleibt alles **auf Deinem Rechner**. Das ist keine Einschränkung, sondern der Plan: Zwei Tage reichen, um etwas Laufendes zu bauen — nicht, um es sicher zu betreiben. Deine Anwendung ist am Ende vollständig da, Du kannst sie jederzeit mit `bin/dev` starten und weiterbauen.

Ins Netz stellen ist ein eigener Schritt mit eigenen Fragen: Wer darf darauf zugreifen, wo liegen die Daten, wer betreibt es. Den gehen wir bewusst nicht nebenbei.

---

## Das Wichtigste im Umgang mit dem Agenten

**Jedes „so nicht" wird zur Regel.** Wenn Dir etwas nicht gefällt — eine Benennung, ein Layout, eine Vorgehensweise — sag es. Claude korrigiert nicht nur die Stelle, sondern schlägt Dir eine Regel vor und schreibt sie nach Deinem OK in `CLAUDE.md`. Ab dann macht er es überall so.

Einmal korrigieren, nie wieder erklären. Das ist der Unterschied zwischen einem Werkzeug und einem Mitarbeiter.

---

## Die drei Dateien

| Datei | Was drinsteht | Wer pflegt sie |
|---|---|---|
| `requirements.md` | **Das WAS** — Ziel, Nutzer, Funktionen, was rausfällt | Du sagst es, Claude schreibt es · geschärft mit `/grill` |
| `CLAUDE.md` | **Das WIE** — Bauregeln, Konventionen, Eure gelernten Regeln | der Harness + Ihr im Lauf des Tages |
| `design-system.md` | **Das AUSSEHEN** — Bausteine und Farben | `/design-system` |

---

## Befehle

| Befehl | Wofür | Wie oft |
|---|---|---|
| `/init-dependencies` | Rechner einrichten | einmal pro Rechner |
| `/init-project "…"` | Projekt aufsetzen | einmal pro Projekt |
| `/grill` | Erzählen lassen + Anforderung schärfen | am Anfang · später gezielt: `/grill <Thema>` |
| `/design-system <url>` | Euer Design einbauen | einmal, optional |
| `/init-hackathon-canvas` | Veröffentlichen einrichten | einmal pro Projekt |
| `bin/dev` | Server starten | ständig |
| `bin/rspec` | Tests laufen lassen | ständig |

Alles andere ist Gespräch.

---

## Wenn etwas klemmt

**„Der Befehl existiert nicht."** Du bist im falschen Ordner — siehe Schritt 2.

**„Your Ruby version is 2.6.10…"** Du hast nach `/init-dependencies` die Unterhaltung nicht neu gestartet. Schließen, neu öffnen.

**Die Seite sieht unformatiert aus.** `bin/dev` neu starten — nach Design-Änderungen muss er einmal durchlaufen.

**Die letzte halbe Stunde war ein Irrweg.** Sag: *„Zurück zum letzten sicheren Stand."* Deshalb sicherst Du zwischendurch ab — siehe unten.

**Ich weiß nicht mehr, wo wir stehen.** Sag: *„Zeig mir kurz, was fertig ist und was noch fehlt."*

**Es läuft gerade gut.** Sag: *„Sicher das ab."* Dann gibt es einen Punkt, zu dem Du jederzeit zurückkannst. Mach das nach jedem Stück, das funktioniert — es kostet fünf Sekunden und rettet Stunden.

> **Was „absichern" nicht umfasst: Deine Daten.** Gesichert wird der Bauplan — der Code. Die Einträge, die Du in der App anlegst, und hochgeladene Dateien liegen daneben und werden **nicht** mitgesichert. Im Workshop ist das egal, die Daten sind erfunden. Arbeitest Du später wirklich damit, kopier Dir den Projektordner gelegentlich woandershin — der Harness macht das nicht für Dich.

**Alles andere:** frag Claude. Ernsthaft — beschreib, was Du erwartet hast und was passiert ist. Für hartnäckige Fälle steht mehr in der `README.md`.
