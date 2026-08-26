# Head-Gate Werkstatt-Portal

Das Portal zum Co-Building-Workshop der Head-Gate GmbH (25./26.08.2026):
Einrichtungsbegleitung, Werkstatt-Cockpit und alle Unterlagen für zwei Tage
Bauen — erreichbar unter **https://headgate.apps.w-ir.digital**, hinter
Authelia auf dem Customer-Edge.

Entstanden aus dem Hackathon-Rails-Harness und mit genau den Werkzeugen
gebaut, die der Workshop selbst benutzt — Claude Code, in wenigen Tagen.
Die App ist damit zugleich ihr eigenes Exponat.

## Was das Portal kann

| Seite | Pfad | Für wen |
|---|---|---|
| Startseite mit Kacheln und Use-Case-Übersicht | `/` | alle |
| **Setup Lotse** — führt Schritt für Schritt durch die Windows-Einrichtung (WSL2, Ubuntu, Git, Node, Claude Code, Ruby, Rails); merkt sich den Fortschritt je Person, Notizfeld für Zugangsdaten | `/installations/…` | alle |
| **Werkstatt-Cockpit** — die neun Use Cases mit Teams, Trainer-Zuweisung, GitHub-Repo, Rollout-Status (offen/gemeldet/verworfen/ausgerollt) | `/use_cases` | Admin, Trainer, Teammitglieder |
| Ablauf beider Tage | `/ablauf` | alle |
| Wissenswertes — Nachschlagen beim Bauen | `/wissenswertes` | alle |
| Präsentationen — die Workshop-Decks im Browser | `/praesentationen` | alle |
| KPI-Dashboard | `/kpis` | alle |
| App Store — ausgerollte Teilnehmer-Projekte | `/app-store` | alle |
| Ausroll-Referenz | `/ausrollen` | Admin |
| Trainer-Briefing (PDF, nicht öffentlich) | `/trainer_briefing` | nur Trainer |
| Harness-ZIP zum Download | `/downloads/hackathon-harness.zip` | alle |

## Anmeldung & Rollen — zwei Ebenen

**Tür: Authelia** (`edge/authelia/users.yml` auf dem Edge, ein Nutzer je
Person, Gruppe `headgate`). Die App liest die durchgereichte `Remote-Email`
und meldet die Person automatisch an — kein zweites Passwort, eigene
Checkliste je Person. Schalter: `TRUST_FORWARD_AUTH` in der Compose-Datei;
nur zulässig, solange die App ausschließlich hinter Traefik erreichbar ist
(Details und die verbotene Mischung mit geteilten Logins:
`docs/EDGE-DEPLOY.md`).

**Rollen: ENV, nicht Datenbank.** `ADMIN_EMAILS` und `TRAINER_EMAILS` in
`deploy/setuplotse.compose.yml` — maßgeblich ist die Adresse aus dem
Authelia-`email:`-Feld, nicht der Benutzername. Änderung = Compose anpassen,
Container neu erzeugen, kein Build.

## Stack

Rails 8 · SQLite (in `storage/`, als Volume gemountet) · Devise · Tailwind ·
RSpec/FactoryBot (`bin/rspec`, aktuell 150+ Beispiele). Design-Tokens nach
Head-Gate-CI: `design-system.md`, Referenzseiten `/design` und `/flow`
(nur Development).

## Betrieb

```bash
# Deploy (vom Rechner mit Edge-Zugang; Gate liegt im customer-edge-Repo):
cd ~/MeinCode/customer-edge
bash scripts/app-deploy.sh setuplotse ~/MeinCode/requirements-installation-website
```

- **`docs/EDGE-DEPLOY.md`** — die App auf dem Customer-Edge: Einrichtung,
  Secrets, Seeds, Anmelde-Architektur, bekannte Eigenheiten. Zuerst lesen.
- **`docs/WERKSTATT-DEPLOY.md`** — Teilnehmer-Projekte am Workshop ausrollen.
- **`docs/EDGE-ZUGANG-EINRICHTEN.md`** — Edge-Zugang für eine zweite Person
  (Tailscale-SSH-Befund vom 23.08. beachten: `authorized_keys` greift auf
  diesem Host nicht, Zugang läuft über die Tailscale-ACL).
- Migrationen laufen bei jedem Containerstart (`db:prepare`); `db/seeds.rb`
  ergänzt nur, überschreibt nie — geänderte Seed-Texte brauchen ein
  manuelles `db:seed` auf dem Edge.
- Workshop-Decks kommen aus dem Vault: `bin/rails decks:sync`
  (Quelle per `DECK_SOURCE` übersteuerbar), Ergebnis liegt committet in
  `workshop_docs/`.

## Herkunft

Der Unterbau (`.claude/skills/`: `grill`, `canvas`, `init-project`,
`init-dependencies`, `design-system`) stammt aus dem Hackathon-Rails-Harness
und bleibt benutzbar — `requirements.md` ist die gewachsene
Produktdefinition dieser App, `QUICKSTART.md` die Teilnehmer-Anleitung des
Harness.
