#!/usr/bin/env bash
# Claude Code hooks — enforces TDD planning discipline and reminds to verify tests.
# Called by settings.json hooks with the event name as the first argument.

EVENT="${1:-}"

case "$EVENT" in

  pre-enter-plan-mode)
    cat <<'MSG'
=== PLANNING REMINDER ===

Structure the plan so that every increment follows the TDD cycle:

  Increment XX: <name> (test -> build -> refactor -> verify)

  RED:      Write one failing test — describe exactly what it tests and why it fails
  GREEN:    Implement minimum code to pass — describe which files to touch
  REFACTOR: Assess and improve if needed — describe what to look for
  VERIFY:   All tests pass

Every increment = one failing test = one behaviour. Never combine two features into one increment.

MSG
    ;;

  stop)
    cat <<'MSG'
=== DONE? ===

Before finishing, run the tests:

  bin/rspec

All tests should be green. If any are failing, fix them before considering the task complete.

MSG

    # Only mention committing when something is actually uncommitted.
    # Silent when the repo is clean, and silent before /init-project has run
    # git init — a reminder that fires every turn stops being read.
    if git rev-parse --git-dir >/dev/null 2>&1 \
       && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
      cat <<'MSG'
=== NOT SAVED YET ===

There are changes that are in no commit. A green test suite that isn't
committed is not a restore point — and the restore point is the only way
back when a later step goes wrong.

If the tests pass, commit now:

  git add -A && git commit -m "<type>: <what changed>"

MSG
    fi

    # The flow page only moves when the node is marked, and the marker is the one
    # step of the TDD cycle that nothing enforces — it depends on remembering a
    # rule from CLAUDE.md across a run of a dozen increments. Same reason the
    # commit reminder exists.
    #
    # Fires only after a commit that actually touched the app, only while steps
    # are still open, and never before /grill has filled the file: the baseline
    # commit from /init-project touches app/ too, and firing there would ask
    # someone to mark a step that does not exist yet. A reminder that fires when
    # it does not apply stops being read.
    if [ -f requirements.md ] && ! grep -q '\[PLACEHOLDER' requirements.md 2>/dev/null \
       && git rev-parse --git-dir >/dev/null 2>&1 \
       && [ -z "$(git status --porcelain 2>/dev/null)" ] \
       && git log -1 --name-only --pretty=format: 2>/dev/null | grep -qE '^(app|spec)/'; then

      FLOW="$(sed -n '/```mermaid/,/```/p' requirements.md 2>/dev/null | grep -c 'flowchart' || true)"
      if [ "${FLOW:-0}" -gt 0 ]; then
        OPEN="$(grep -oE '[A-Za-z0-9_]+\[[^]]+\](:::[a-zA-Z]+)?' requirements.md 2>/dev/null | grep -vc ':::' || true)"
        if [ "${OPEN:-0}" -gt 0 ]; then
          cat <<'MSG'
=== STEP NOT MARKED ===

You committed work on the app, and the flow in requirements.md still has
steps without a marker. If the step you just finished now works for the
user end to end, mark it:

  C[Notizen schreiben]:::fertig

Only mark what is green, and only when the whole step works — not after the
first of its increments. Until you do, http://localhost:3000/flow shows the
team as slower than they are, and that is the page they check when they
wonder whether they will make it.

MSG
        fi
      fi
    fi
    ;;

  *)
    echo "hooks.sh: unknown event '${EVENT}'" >&2
    exit 0
    ;;

esac
