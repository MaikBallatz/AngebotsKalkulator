---
name: grill
description: Turn what the team says into requirements.md, then harden it one question at a time. Run right after /init-project. Pass a topic to re-sharpen just that point later. Usage: /grill  OR  /grill search
disable-model-invocation: true
user-invocable: true
---

<!--
provenance:
  quelle: github.com/mattpocock/skills — skills/productivity/grilling/SKILL.md (+ grill-me trigger)
  stand: 2026-07-26
  lizenz: MIT (Matt Pocock) — adaptierte Eigenfassung, Notice in LICENSE
  audit: 2026-07-26 (kein Shell-/Netzwerk-/Secret-Zugriff im Original; reines Gesprächsprotokoll)
  lokale-aenderungen: auf requirements.md fokussiert; Antwortsprache = Teilnehmersprache;
    Endzustand = aktualisierte requirements.md + Übergabe an Plan-Modus; Hackathon-Zeitbox;
    2026-08-04 Phase 1 (Zuhören) und gezielter Nachschliff ergänzt
-->

# Grill

This skill owns the WHAT. It gets `requirements.md` written, then makes it hold up.

## Pick your mode first

Read `requirements.md`, then choose — do not ask the user which mode to use:

| State | Mode |
|---|---|
| File still contains `[PLACEHOLDER` markers | **Phase 1, then Phase 2** |
| File is filled, no topic given | **Phase 2 only** — full pass |
| File is filled, a topic was given (`/grill search`) | **Targeted re-run** — that topic only |

Also read `CLAUDE.md` and explore the repo for anything already answered there — models, routes, seeds. Never ask for facts you can look up yourself; interrogation is for **decisions only**.

---

## Phase 1 — Listen

Only when placeholders remain. The team has not written anything yet, and asking them to fill a form produces three bullet points and silence. So you listen first.

**Open with this, in their language:**

> "Erzähl mir einfach, was Du bauen willst — so, wie Du es einem Kollegen in der Kaffeeküche erzählen würdest. Ich unterbreche nicht, und ich sortiere nichts mit. Das mache ich danach.
>
> Fang am besten hier an: **Welche Aufgabe in Deiner Woche nervt Dich am meisten — und wer sitzt daneben, wenn sie anfällt?** Erzähl den letzten konkreten Fall, nicht die allgemeine Regel. Zwei, drei Minuten reichen. Unsortiert ist genau richtig."

The working part is *"the last concrete case, not the general rule."* Ask a professional for requirements and you get bullet points; ask about last Tuesday and you get actors, sequence, exceptions and the annoyance — which is exactly what the file needs.

**Five rules while listening. They are constraints, not style:**

1. **Ask nothing.** No clarifying questions, no "just quickly: who uses this?". You have exactly two speaking turns: the opening above, and — once they fall silent — a single *"Was fehlt noch?"*
2. **Don't take structured notes out loud.** The file is written *after* the telling, not during. Throwing lists back mid-story creates pressure to justify, and they switch to bullet points.
3. **Write down who and what hurts.** The opening asks who is sitting there when the annoying task comes up, and what the annoyance is — those answers used to be dropped after the file was written. They go into **Who it is for** and **What hurts today**, in the participant's words.

   Then decide, do not ask: names only themselves → they *are* the user, believe them. Names other people → every statement about those absent is a **guess**. Mark it as one, and add a line to the success criterion: *„Vor dem Ausrollen mit einer echten Kollegin gegenprüfen."*

4. **Phase 1 ends when the *form* is complete, not the *substance*.** Write `requirements.md` from what you heard, guessing where you must. The moment no `[PLACEHOLDER` marker remains, Phase 1 is over — even if entries are rough, lopsided or half wrong. Closing gaps is Phase 2's job. Without this rule you start hunting for quality here, and hunting for quality means asking questions.
5. **No judgement on what was said.** Never "that was still thin". What they said becomes the file; sharpness comes in Phase 2, with a recommendation behind it.

**Then hand over, out loud:**

> "Danke. Ich schreibe das jetzt in `requirements.md` und zeige Dir, was ich verstanden habe — dann korrigierst Du. Danach stelle ich Dir ungefähr zehn Fragen, jede mit meinem Vorschlag."

### The read-back — draw it, don't recite it

**This is where Phase 1 succeeds or fails.** People nod at prose and argue with pictures, and a nod here costs the afternoon. So the read-back is the *path*, not a paragraph.

Fill the mermaid block under **Primary Workflow** while you write the file: one node per step, `flowchart LR`, the team's own words as labels, **at most ten nodes**. A branch only where the app genuinely forks — `C -->|abgelehnt| E` — never for a variation you invented.

**A step may carry a second line, and only where it carries something.** When they named parts that matter — three fields, a sort order, a rule — write them into the node instead of splitting it into more boxes:

```
C[Notizen schreiben<br/>Stärken · Bedenken · Empfehlung]
```

The page also reads a mermaid `subgraph` the same way and folds its inner nodes into that second line, so either notation works.

**Not on every box.** One detail line where it matters keeps the row readable; one on all six turns the path back into the wall of text it exists to replace. If a step genuinely needs three increments, it is a node too big — split it **in the plan**, not in the diagram. The diagram stays at the level the team thinks at.

Then, in the chat, do three things and nothing else:

1. Number the path in one line per step. Mermaid does **not** render in Claude Desktop's Code tab, so never paste the diagram source at them — it reads as gibberish.
2. Point at the page: *"Das steht jetzt auch als Bild unter http://localhost:3000/flow — lad es einmal neu."*
3. Ask **one** question, in this form: **"Wo ist das falsch?"**

Not *"stimmt das?"* and not *"passt das so?"*. Both invite a yes. Asking where it is wrong assumes something is, and that assumption is what gets the correction out.

Then correct the diagram from what they say, and only then move to Phase 2.

---

## Phase 2 — The interview loop

- Ask **exactly one question per round**. Never bundle questions.
- Every question comes **with your recommended answer** and a one-line reason. The team should mostly be saying "yes" or picking between two options.
- Tell them where they are: *"Frage 4 von etwa 10."* Without a counter it feels endless.
- Work the decision tree in dependency order: users & ownership → core entities → the one primary workflow → scope cuts (what is OUT for the hackathon) → success criterion for the day-2 demo.
- **If you came from Phase 1, start with what you guessed.** Those entries are yours, not theirs — put them up for correction first.
- Answer in the language the user speaks (German team → German questions).
- After each answer, update `requirements.md` immediately — the file is the single source of truth, not the chat.

### Hackathon timebox

This is a two-day build, not a product spec. 8–12 questions is the norm. Prefer a hard scope cut over an open question: when in doubt, recommend "out of scope for the hackathon" and move on.

---

## Targeted re-run

`/grill search` — a topic was named. The team is mid-build and one point stopped holding. Do **not** restart the tree; they already answered it once, and re-asking settled questions reads as punishment, not help.

- Confirm the scope in one line: *"Wir schärfen nur die Suche nach — der Rest bleibt."*
- Two to four questions, same rules as Phase 2.
- Update only the affected part of `requirements.md`.
- Close with what changed and what it means for what is already built.

---

## When a team asks for more than a path

Some teams — usually the ones with an IT background — want a data model, a state
machine, scenarios, or BPMN. **Never offer this.** The path is enough for two days,
and a second notation is a second thing to keep true.

But when they ask, give it: write an **additional fenced block** into
`requirements.md` and say the page already shows it.

| They ask for | Write into `requirements.md` |
|---|---|
| the data model | a fenced `mermaid` block starting with `erDiagram` |
| statuses, a lifecycle | a fenced `mermaid` block starting with `stateDiagram-v2` |
| acceptance criteria, test cases | a fenced `gherkin` block — Szenario / Gegeben / Wenn / Dann |
| BPMN, because the company runs on it | a fenced `xml` block with BPMN 2.0 |

`/flow` folds each of them away below the path — visible only to whoever opened it.
The first three it draws; BPMN it shows as source with a pointer to bpmn.io, because
rendering it would need a library this harness will not carry.

**One notation beyond the path, not three.** If a team wants two, ask which one they
would keep, and write that one.

## Ending condition

Stop when you can honestly say: someone else could build this from `requirements.md` alone. Then:

1. Show the team the final requirements.md summary (5 lines max).

   **Redraw the flow first.** The scope cuts changed the path — steps fell away, a branch was closed. Update the mermaid block, then send them back to `http://localhost:3000/flow` with one sentence naming what is gone: *"Zwei Schritte weniger als vorhin — der Export und die Freigabe sind draußen."*

   This is the only moment the team sees what a scope cut actually bought them. A shorter path is a visible win, where a list of cut features reads like loss. Draw it twice — here and in Phase 1 — and never a third time; the diagram is a mirror, not a deliverable.
2. **Bring CLAUDE.md back in line — three guessed spots, not two.** `/init-project` filled them by *guessing* from a one-sentence brief, before requirements.md existed. The interview you just ran is the first time those facts are settled. Rewrite with the entity names that are actually true now, and drop any that no longer exist:

   - Part 1 → "Ownership model"
   - Part 1 → "Scoping every query"
   - Part 2 → Testing, last bullet: *"Every spec that creates … MUST pass `user: user`"* — this one is easy to miss and carried invented model names through a whole real session.

   Do not touch anything else in CLAUDE.md.

   Why this matters: those scoping examples are what keeps one user from seeing another user's data. Stale model names there turn a security rule into noise — and it shows up in the demo, when the second person signs in.
3. **Run the demo rehearsal.** This is where the team stops answering and starts *seeing*, and it is the last moment where imagining the result can still shape the whole build rather than comment on it.

   **Do not announce it as another question.** Open with the scene:

   > "Es ist morgen um 16 Uhr. Dein Laptop hängt am Beamer, die anderen Teams schauen zu, Du hast drei Minuten. **Was zeigst Du zuerst?**"

   Then two follow-ups, and the third is the one that matters:

   > "Und was sagst Du dazu, während Du es zeigst?"
   > "Jemand fragt: *und was bringt das?* — was antwortest Du?"

   That last answer is the user value, in the words the participant will actually use tomorrow. Write all of it into the **The Demo** section of `requirements.md`, three to five lines, their phrasing not yours. Then read it back once.

   **Why it earns its fifteen minutes:** whoever can picture the result notices when the agent builds something else, and can cut, because they know what they would miss. Both are the abilities teams lack at four in the afternoon.

   ### When the rehearsal fails

   Some teams cannot tell it. **That is a finding, not a failure of the person** — and it means the requirement is still too wide to build from. Say so in those words:

   > "Das liegt nicht an Dir. Wenn sich der Auftritt nicht erzählen lässt, ist der Auftrag noch zu weit — lass uns zwei Sachen enger machen, dann geht es."

   Then **go back into the question loop**, targeted: two or three questions on the vaguest core feature, then rehearse again. Do not hand over to plan mode with an untellable demo; building it would only postpone the same conversation to tomorrow afternoon, when it costs a day instead of five minutes.

4. Ask the **one** question that isn't about the WHAT — because it is the only moment anyone thinks of it. Offer all three sources, not just the website; teams that have a brand manual but no usable site will otherwise say "no":

   > "Habt Ihr ein Corporate Design, dem die App folgen soll? Drei Wege: Eure **Website-Adresse**, ein **Markenhandbuch** — leg die Datei einfach in den Projektordner und sag mir den Namen — oder **beschreib es mir in Worten** ('Petrol und warmes Grau'). Wenn nichts davon passt, bleiben wir beim neutralen Standard."

   **Record the answer, do not apply it.** Write one line into the *Applied design* section at the bottom of `design-system.md`:

   ```
   - **Source noted:** https://example.com — captured during /grill, not yet applied
   ```

   Then say: *"Notiert. Wir wenden es am zweiten Tag an — dann hat die App Inhalt und Du siehst den Unterschied richtig."*

   **Why it waits.** Applied now, against an empty app, the corporate design is a colour change nobody notices. Applied on day 2, the whole app and the design page turn over at once, in front of the team — the strongest two minutes of the workshop. Running `/design-system` early spends that for nothing.

   Don't extract anything here; that skill does the work.
5. **Hand over the two addresses — this is the moment they mean something.**

   From here the team builds, and a trainer is at another table. `/init-project` named both pages hours ago, before anything about them was meaningful; nobody remembers. Name them again now, and name them as **questions**, not as URLs — a participant does not think "I need the design page", they think "why does it look like that":

   > "Zwei Adressen, damit Du nachschauen kannst, ohne jemanden zu fragen:
   >
   > **http://localhost:3000/flow** — was wir gerade verabredet haben: Dein Auftritt von morgen, der Weg, und wie weit ich damit bin. **Schau da hin, wenn Du wissen willst, ob ich das Richtige baue.**
   >
   > **http://localhost:3000/design** — die Bausteine und wie sie heißen. **Schau da hin, wenn Dir etwas am Aussehen nicht gefällt** — mit dem Namen von dort treffe ich es beim ersten Versuch.
   >
   > Von jeder Seite kommst Du unten zur anderen."

   Keep it to these three lines. A longer handover gets skipped, and then it is worth nothing.

6. Say: "Ready. Next step: ask me for a plan — 'Stell mir einen Plan vor.'"

On a targeted re-run, do steps 1 and 6 only — no rehearsal and no handover, the demo stands and they know the addresses.

Do **not** start planning or building inside this skill.
