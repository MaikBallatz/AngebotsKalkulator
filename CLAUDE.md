# AngebotsPilot - Angebotskalkulator für den Handel

> **Two files run this project — plus one for the look.**
>
> - `requirements.md` — **the WHAT.** Goal, users, features, scope cuts. Owned by the team, hardened with `/grill`.
> - `CLAUDE.md` (this file) — **the HOW.** Stack, conventions, architecture, anti-patterns.
> - `design-system.md` — **the LOOK.** Tokens, components, layout conventions.
>
> When WHAT and HOW disagree: `requirements.md` decides *what* gets built, `CLAUDE.md` decides *how* it gets built.

---

## Before you build anything

1. **Read `requirements.md`.** Every time you enter plan mode — not just once at the start.
2. **If `requirements.md` still contains unfilled `PLACEHOLDER` markers, do not build.** Do not guess the missing half either. Say: *"Die Anforderung steht noch nicht — sag `/grill`, dann gehen wir sie zusammen durch."* `/grill` handles the empty file: it listens first, writes the file, then hardens it. Building on an unclear WHAT is the most expensive mistake in a two-day build.
3. **Read `design-system.md` before you touch anything under `app/views/`.** Every time. It is the only place the component classes are defined.
4. **Plan before code.** No implementation without an approved plan in the format below.
5. **Stay inside scope.** Anything listed under *Explicitly OUT of scope* in `requirements.md` stays out — even if it's easy, even if it's obvious. Cutting is winning.

---

# Part 1 — This project

*Filled once by `/init-project`. Everything below Part 1 is harness standard and rarely changes.*

## What we're building

AngebotsPilot hilft kleinen Handelsunternehmen, Angebote schnell und nachvollziehbar zu kalkulieren: Produkte mit Einkaufspreis pflegen, daraus Angebotspositionen mit Aufschlag/Marge zusammenstellen und dem Kunden ein fertiges Angebot geben.

## Ownership model

Kein Nutzer-Ownership. Offener Zugang ohne Login — das hier ist ein gemeinsames internes Team-Tool, keine Datentrennung zwischen Personen. `Consultant` (Berater:in) ist eine feste, editierbare Stammdaten-Liste (Name + E-Mail, aktiv/inaktiv), kein Account. `Quote` (Angebot) trägt ein Feld `consultant` als Referenz auf diese Stammdaten — nicht auf einen User. Alle sehen alle Quotes.

## Scoping every query

Es gibt keine `current_user`-Scoping-Pflicht in diesem Projekt — es gibt keine Accounts, an denen sich Daten unterscheiden könnten:

- Quotes: `Quote.all` / `Quote.find(params[:id])` ist hier korrekt
- Consultants: `Consultant.all` ist hier korrekt
- Devise/Login wird für den App-Zugriff nicht verwendet

Das ist eine bewusste, im Grill-Interview bestätigte Abweichung vom Standard-Gerüst — nicht vergessen (aber auch nicht wegwischen), wenn diese Datei später einmal für ein anderes Projekt als Vorlage dient.

The steps for adding a new user-owned model are in `.claude/rules/database.md`, which loads whenever you touch `db/` or `app/models/`.

---

# Part 2 — House rules

## TDD process

Work one increment at a time. For every feature increment:

**RED** — Write one failing test. Only one. Verify it fails for the right reason (not a syntax error or missing dependency).

**GREEN** — Write the minimum code to make that one test pass. No extras, no cleanup yet.

**REFACTOR** — Look at what you just wrote. Is there duplication? Confusing naming? Fix it now, while the test is green.

**VERIFY** — Run `bin/rspec`. All tests pass. **Then commit** — every green state is a restore point, and the only way back when a later increment goes wrong. Only then move to the next increment.

**MARK** — When the **step** is finished, mark it in the flow block of `requirements.md`: `C[Notizen schreiben]:::fertig`. Nothing else changes — same node, same label, one marker.

**A commit is not a step.** One node often takes two or three increments, so you commit two or three times inside it — the commit is the restore point, the marker is the promise that this part of the path now works. Mark after the increment that makes the step work **for the user, end to end**; that is the same increment whose "what the user gets back" line describes the step itself. Marking after the first of three is the fastest way to make the page lie, and it lies in the direction that flatters us. Mark at the commit and nowhere else — `http://localhost:3000/flow` then shows how far the path is built, which is the question everyone in the room is actually asking at three in the afternoon.

A hook reminds you after a commit that touched `app/` while steps are still open — the same way it reminds you to commit at all. Both exist because both depend on remembering a rule across a run of a dozen increments, and that is exactly what fails.

If a node is already satisfied before you build anything — sign-in is wired by `/init-project` — mark it and say so. An honest head start reads better than a step that mysteriously completes in one minute.

If a test is red for a different reason than the one you announced in RED, say so explicitly: *"this is red, but not the way I planned — that's a fault, not progress."* Never leave the team to work out which kind of red they are looking at.

**Two failed fixes at the same test — stop.** Count per example, not per error message: a red that fails for a new reason is still the same stuck step, and a third variation is not persistence, it is where the afternoon goes. (A test that fails differently on every run is itself a reason to stop and say so.) Say where you stand in one sentence, then offer two ways out with a recommendation: **shrink the step** — name the simpler version concretely; the diagram may change, it belongs to the team — or **park it** and reset to the last green commit; that is what the restore points are for. Park only if no open main-path node builds on the step — check the flow, don't guess — and say what the demo will lack. Never leave a red or pending example in the suite. While fixing, follow the failure message wherever it points — the fault is often a missing migration, a factory, a route, not the file you just edited — but do not re-read the plan or `requirements.md` for a new approach, do not refactor, do not add files.

## Plan format

**Every increment names what the user gets back.** One line per increment, before RED: *"Danach sieht die Beraterin ihre Gespräche als Liste, neueste zuerst."* If that line cannot be written, the increment is plumbing — either fold it into the one that delivers something or say out loud that this step pays off only with the next.

**Derive the increments from the flow.** `requirements.md` holds the primary workflow as a mermaid block — one node per step, in order. Walk it from the first node and build in that sequence: the team can follow their own path being built, and the demo runs the same path end to end.

Three rules follow from it:

- **Never build a step that is not a node.** If the work you are about to plan has no place on the path, it is out of scope — say so instead of planning it.
- **A node that turns out to need three increments is a node too big.** Split it in the plan, not in the diagram; the diagram stays at the team's level of detail.
- **If the flow branches, the main path comes first** — every node on it working end to end before the first branch increment. The main path is the numbered line `/flow` draws, and it is the path the demo walks; if those two disagree, that is a requirements fault — say so instead of deciding silently. A finished branch off a broken main path shows nothing at four o'clock. On a linear flow this rule is silent.

**Draw the demo line.** Every plan marks the increment after which the demo runs end to end: one line, *everything below this is upgrade, not requirement*. When time runs short, cut from the bottom — that decision was made in the morning, not in the four-o'clock panic.

Every plan MUST structure increments exactly like this:

```
Increment XX: <increment name> (test -> build -> refactor -> verify)

RED: write one test that fails because of <reason>

GREEN: implement simplest next implementation that is expected to make that test pass

REFACTOR: consider if the code is good quality and has no design smells, and refactor if needed

VERIFY: all tests passing, functionality is working as expected
```

## Coding conventions

- Use `&.` (safe navigation operator) instead of nil checks
- Use double-quotes by default for strings
- Write self-documenting code — good names over comments

## Testing (RSpec)

- Write integration tests as request specs (`spec/requests/`)
- Test features from the user's perspective, not technical internals
- Use FactoryBot to create test data
- Check rendered HTML to verify output
- Mock only 3rd-party external APIs — never mock your own code
- When signing in during request specs, specify devise scope: `sign_in user, scope: :user`
- Quotes and Consultants have no user association — specs create them without a `user:` argument

## Architecture: not-so-fat controllers, not-so-fat models

Put logic where it belongs — don't default to stuffing everything in models.

**Models — domain-wide logic:**
- Validations, associations, scopes, calculations that are used everywhere
- Do NOT add speculative logic "we might need this someday"
- Prefer explicit method calls over callbacks; use callbacks only for data integrity that must always apply

**Controllers — use-case specific logic:**
- Orchestrate the request: find data, call domain logic, render response
- Logic that only makes sense for one specific action stays in the controller

**View helpers — presentation logic:**
- Formatting, labels, display-only transformations
- Only logic that doesn't depend on request context (params, session)

**When logic doesn't fit neatly, use these in order:**

1. **Controller concern** — when multiple controllers need the same logic
2. **Service object** (`app/services/`) — for complex operations involving external systems or multiple models. Single public method. Never call one service from another.
3. **Plain Ruby object** — for domain concepts not stored in the database

## Where the rest lives

Two areas load their own rules when you touch them, so they are not repeated here:

- **Database and migrations** → `.claude/rules/database.md` (fires on `db/**`)
- **Views, styling and client-side JavaScript** → `.claude/rules/views.md` (fires on `app/views/**`, `app/helpers/**`, `app/javascript/**`, `app/assets/tailwind/**`)

## Commands

- `bin/rspec` — run all tests
- `bin/rspec spec/requests/` — run request specs only
- `bin/dev` — start dev server (Rails + Tailwind watcher)
- `bin/rails db:migrate` — run pending migrations
- `bin/rails db:rollback` — undo last migration
- `bin/rails runner` — run a Ruby script in the app context (use instead of rails console)

Project workflow: `/grill` — it listens, writes `requirements.md`, then hardens it → ask for a plan → build. Nobody fills the file by hand.

## Demo data

An empty app demos badly. A team that finishes building at 15:45 then shows *forms* instead of *results*, and everything they built disappears behind a blank list.

**So: once the first resource holds data, put believable examples in `db/seeds.rb`** — roughly ten rows, real-sounding names and dates from the team's own domain, never `Test 1 / Test 2`. Reload with:

```bash
bin/rails db:seed
```

Make it idempotent with `find_or_create_by`, so it can be run twice without doubling anything. Offer it before the demo if nobody asks — it is the cheapest quality jump available on day two, and the team will not think of it themselves.

## Abnahme — before anything counts as finished

A green suite is necessary and not sufficient: it exercises what the tests thought of, not what the demo will do. A real session shipped a server that could not start for want of an API key — every test green. After the last increment, two checks, both manual, both cheap:

1. **Walk the Demo.** Run the path from `requirements.md`'s *The Demo* section against the running app, by hand, from a fresh sign-in — the same clicks in the same order the team will perform tomorrow. Anything that breaks here would have broken on stage.
2. **The scoping probe.** Register a **second account** and verify it cannot reach the first account's data — not the lists, not the detail pages, not by guessing an ID in the URL. Part 1's ownership rule is enforced by discipline; this is the one moment it gets *proven* instead of asserted. It is also the demo's most embarrassing possible failure, found ten minutes early.

Report both results explicitly. Only after both pass, say the build is done.

**Never put `destroy_all` in seeds, and never delete rows to "start clean".** On day two the database holds sample data and clearing it costs nothing. Weeks later the same file holds the team's real work, the same sentence — "füll mir Beispieldaten ein" — reaches the same script, and it is gone. Seeds only ever add.

If real records already exist and the team asks for demo data anyway, say so first: *"Da stehen schon 14 echte Einträge drin. Ich lege Beispiele dazu, ich lösche nichts — soll ich?"*

## Git commits

- Use conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `style`, `test`, `chore`
- Keep messages concise — focus on what changed and why
- **NEVER** add AI attribution lines (no "Generated with Claude Code", no "Co-Authored-By: Claude")

---

# Part 3 — Design system

Plain Tailwind utility classes. No DaisyUI, no custom CSS files.

**The design system lives in its own file: `design-system.md`.** Read it before you touch anything under `app/views/` — it holds the token roles, the component catalogue and the layout conventions.

Two things you must know without opening it:

- **The values live in exactly one place**: the `@theme` block in `app/assets/tailwind/application.css`. Nowhere else.
- **Never write a raw color, radius or font into a view.** No `bg-blue-600`, no `bg-[#E2001A]`, no inline styles. If something is missing, it becomes a token first — then you use it.

To apply a customer's corporate design, run **`/design-system <url, description, or file>`**. Do not hand-pick brand colors.

---

# Part 4 — Anti-patterns

Never do these. They are the mistakes that cost a hackathon team its second day.

- **Never query unscoped.** No `Model.all` or `Model.find` in a controller — always through `current_user` (see Part 1).
- **Never write code before a failing test.** No RED, no GREEN.
- **Never combine two features into one increment.** One increment = one failing test = one behavior.
- **Never mock your own code.** Only 3rd-party external APIs.
- **Never build past `requirements.md`.** Out of scope stays out, even when it's a five-minute job.
- **Never invent a UI pattern** that isn't in the component table in `design-system.md`. Add it there first.
- **Never build a modal, a spinner or a dropdown.** Destructive actions use `turbo_confirm`, loading uses Turbo's own progress bar, and a menu becomes a page. All three are in `design-system.md`.
- **Never ship a destructive action without a confirmation.** `data: { turbo_confirm: "…" }` on every delete, no exceptions.
- **Never build a screen that only takes.** Whoever types something gets something back — a list that grows, a number that changes, a result that was not there before. A form on top of a database is not an application, and it is what a two-day build degenerates into when nobody watches.
- **Never add speculative logic** for a requirement nobody has stated. Build it when the requirement arrives.
- **Never call a service object from another service object.** Orchestrate both from the controller.
- **Never put domain logic in a Stimulus controller.** Business rules stay server-side; Stimulus only handles interaction.
- **Never add a Node build step.** Import maps only.
- **Never parse a data format by hand** — use a proper library (Ruby's `CSV`, `JSON`, `URI`).
- **Never ask for, echo, or write secrets.** API keys go into `.env` (gitignored), typed by the team themselves — never into the chat, never into a committed file, never into a code sample. Load them with `ENV.fetch("KEY_NAME")`; dotenv is already in the Gemfile. A key that has appeared in the chat or in a tracked file is burned and must be rotated. If a team pastes one anyway, say so and have them rotate it — do not repeat it back.
- **Never create documentation files proactively.** Edit an existing file, or answer in chat.

---

# Part 5 — Rules we learned

Every *"no, not like that"* from the team ends up here. That is how this file gets sharp: corrected once, never repeated.

**How this works — the agent's job.** When the team rejects something you produced — a naming choice, a layout, a library, a pattern — don't just fix that one spot. Follow these four steps:

1. **Check first whether a rule already covers it.** Search Parts 2, 3 and 4 and the list below. If one is close but too vague, **sharpen that rule where it stands** instead of adding a second, competing one. Two rules pulling in different directions are worse than one blunt rule — when instructions contradict each other, the outcome becomes arbitrary.
2. **If nothing covers it, propose one line** for the list below, in the team's words, and **ask before appending it.** Never add a rule the team didn't confirm.
3. **Write it so a stranger could apply it:** name the thing, name the alternative. Date it.
4. **Keep the list at ten rules or fewer.** It is a working set, not an archive. To add an eleventh, merge two existing rules or drop one that has gone stale — and say which, so the team can object.

One correction = one rule. A rule that only fits the single case that triggered it is noise; write the general form or write nothing.

- *(example — delete this when you add your first real rule)* `2026-08-04` — **No modal dialogs.** Confirmations happen on a full page with a visible back link.
