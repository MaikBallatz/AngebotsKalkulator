#!/usr/bin/env bash
# make-zip.sh — baut das Teilnehmer-ZIP aus dem Repo.
#
# Warum ein ZIP und nicht das Repo: Am Workshop-Morgen ein privates GitHub-Repo zu
# klonen scheitert an der Authentifizierung (GitHub hat Passwort-Login über HTTPS
# abgeschaltet; es bräuchte Token, SSH-Schlüssel oder Credential-Manager). Das will
# niemand vor acht Leuten debuggen. Das ZIP geht über Stick oder Netzlaufwerk.
#
# Warum dieses Skript und nicht der Finder — beide Handwege haben je einen Fehler,
# beide sind am 17./18.08.2026 real passiert:
#   * Rechtsklick auf den ORDNER  -> Punktdateien sind drin, aber das Archiv enthält
#     eine zusätzliche Ebene. Windows' "Alle extrahieren" legt noch eine dazu, der
#     Teilnehmer wählt in Claude Desktop den äußeren Ordner, und /init-dependencies
#     existiert dort nicht.
#   * Markieren des INHALTS -> flach, aber der Finder blendet Punktordner aus:
#     .claude/ und .ruby-version fehlen. Ohne .claude gibt es keine Skills, ohne
#     .ruby-version bricht /init-dependencies in Schritt 0 ab.
#
# Dieses Skript packt FLACH (kein umschließender Ordner) und prüft nach dem Bauen,
# dass beides drin ist.
#
# ⚠️ CLAUDE.md und requirements.md kommen NICHT aus der Repo-Wurzel, sondern aus
# harness_template/. Grund, gefunden am 24.08.2026: dieses Repo IST inzwischen die
# gebaute Head-Gate-App — seine eigene CLAUDE.md/requirements.md beschreiben Head-Gate,
# nicht mehr den leeren Platzhalter-Zustand. Die zuletzt ausgelieferte ZIP war (durch
# Zufall, nicht Absicht) noch korrekt: gebaut, bevor die Wurzel-Dateien Head-Gate-
# spezifisch wurden, seither nie neu gebaut. Ein Rebuild direkt aus der Wurzel hätte
# jedem Teilnehmer diese App als Start-CLAUDE.md untergeschoben. harness_template/
# haelt die pristinen, generischen Fassungen dauerhaft fest — unabhaengig davon, wie
# weit die Wurzel-Dateien inzwischen ausgefuellt sind.
#
# Aufruf:  bash bin/make-zip.sh [zielordner]
# Ergebnis: <zielordner>/hackathon-harness.zip  (Standard: ./dist)

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$REPO/dist}"
ZIP="$OUT/hackathon-harness.zip"

cd "$REPO"

# --- Positivliste: was aus der Repo-Wurzel mitkommt. Bewusst nicht "alles ausser X". ---
# CLAUDE.md und requirements.md ABSICHTLICH nicht hier drin — die kommen aus
# harness_template/, siehe Kommentar oben.
INHALT=(.claude .canvas.config .gitignore .ruby-version bin
        design-system.md Gemfile LICENSE QUICKSTART.md README.md)

VORLAGE=(harness_template/CLAUDE.md harness_template/requirements.md)

for p in "${INHALT[@]}" "${VORLAGE[@]}"; do
  [ -e "$p" ] || { echo "FEHLER: $p fehlt im Repo — Harness unvollständig."; exit 1; }
done

# --- Vorprüfung 0: die Vorlage muss noch Platzhalter sein, kein echter Projektstand ---
for v in "${VORLAGE[@]}"; do
  grep -q 'PLACEHOLDER' "$v" || {
    echo "FEHLER: $v enthaelt keine PLACEHOLDER-Markierungen mehr — sieht nach"
    echo "echtem Projektinhalt statt einer leeren Vorlage aus. Pruefen, bevor gebaut wird."
    exit 1
  }
done

# --- Vorprüfung 1: keine Arbeitsstände ausliefern ---
if find .claude bin -name '*.bak*' -print -quit 2>/dev/null | grep -q .; then
  echo "FEHLER: .bak-Dateien würden mitgehen:"; find .claude bin -name '*.bak*'; exit 1
fi

# --- Vorprüfung 2: kein Deployment-Ziel verraten ---
if grep -qE '^CANVAS_(HOST|DOMAIN)="[^"]+"' .canvas.config 2>/dev/null; then
  echo "FEHLER: .canvas.config enthält einen echten Host — der ginge an den Kunden:"
  grep -E '^CANVAS_(HOST|DOMAIN)=' .canvas.config
  echo "Vor dem Ausliefern leeren."; exit 1
fi

# --- Vorprüfung 3: grober Secrets-Blick ---
TREFFER=$(grep -rIlE '(ghp_[A-Za-z0-9]{20}|sk-[A-Za-z0-9]{20}|BEGIN [A-Z ]*PRIVATE KEY)' \
  "${INHALT[@]}" "${VORLAGE[@]}" 2>/dev/null || true)
if [ -n "$TREFFER" ]; then
  echo "FEHLER: mögliche Geheimnisse in:"; echo "$TREFFER"; exit 1
fi

mkdir -p "$OUT"
rm -f "$ZIP"

# -X: keine macOS-Metadaten (kein __MACOSX beim Entpacken unter Windows)
# .claude/worktrees und settings.local.json sind aus demselben Grund wie im
# .gitignore (global bzw. .git/info/exclude) draussen: lokaler Arbeitsstand,
# nicht Teil des Harness. worktrees/ hat das erste ZIP auf 8,4 MB aufgeblaeht
# (21 MB Kopie eines fremden Worktrees), bevor das hier aufgefallen ist.
zip -q -r -X "$ZIP" "${INHALT[@]}" \
  -x '*.DS_Store' -x '*/.DS_Store' -x '*.bak' -x '*.bak-*' -x '.git/*' \
  -x '.claude/worktrees/*' -x '.claude/settings.local.json'

# CLAUDE.md/requirements.md separat dazu, mit -j (Pfad kappen) — landen im ZIP auf
# oberster Ebene als CLAUDE.md/requirements.md, nicht als harness_template/CLAUDE.md.
zip -q -j -X "$ZIP" "${VORLAGE[@]}"

# --- Nachprüfung 1: flach? Kein umschließender Ordner, keine Fremdkörper ---
# Listing EINMAL einlesen. Nicht in Pipes pruefen: `grep -q` schliesst die Pipe,
# `unzip` faengt sich ein SIGPIPE, und `set -o pipefail` macht daraus einen Abbruch.
LISTE=$(unzip -Z1 "$ZIP")

ERLAUBT='^(\.claude|\.canvas\.config|\.gitignore|\.ruby-version|bin|CLAUDE\.md|design-system\.md|Gemfile|LICENSE|QUICKSTART\.md|README\.md|requirements\.md)$'
FREMD=$(awk -F/ '{print $1}' <<< "$LISTE" | sort -u | grep -vE "$ERLAUBT" || true)
if [ -n "$FREMD" ]; then
  echo "FEHLER: unerwartete Einträge auf oberster Ebene:"; echo "$FREMD"; exit 1
fi

# --- Nachprüfung 2: die Dateien, an denen es zweimal gescheitert ist ---
for f in .claude/skills/init-dependencies/SKILL.md .ruby-version CLAUDE.md QUICKSTART.md; do
  grep -qxF "$f" <<< "$LISTE" || { echo "FEHLER: $f fehlt im ZIP."; exit 1; }
done

# --- Nachprüfung 3: die ausgelieferte CLAUDE.md/requirements.md sind noch die Vorlage ---
for f in CLAUDE.md requirements.md; do
  unzip -p "$ZIP" "$f" | grep -q 'PLACEHOLDER' || {
    echo "FEHLER: $f im ZIP enthaelt keine PLACEHOLDER mehr — falsche Datei erwischt?"
    exit 1
  }
done

DATEIEN=$(grep -vc '/$' <<< "$LISTE" || true)
GROESSE=$(du -h "$ZIP" | cut -f1)

echo "✓ $ZIP"
echo "  $DATEIEN Dateien · $GROESSE · flach gepackt"
echo "  geprüft: .claude/skills/ · .ruby-version · kein .git · kein __MACOSX"
echo
echo "  Weitergabe an Teilnehmende:"
echo "    1. Einen leeren Projektordner anlegen (z. B. mein-projekt)"
echo "    2. Das ZIP DORT HINEIN entpacken — danach muss CLAUDE.md direkt darin liegen"
echo "    3. In Claude Desktop: Reiter Code, Umgebung WSL (Windows), Select folder"
echo "       auf genau diesen Ordner"
echo "    4. '/' tippen — steht /init-dependencies in der Liste, stimmt der Ordner"
