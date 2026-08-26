---
name: init-hackathon-canvas
description: One-time setup for Canvas hackathon deployment. Checks your SSH key, wires up the git remote, and outputs the public key to send to the facilitator. Run this once before your first deploy.
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash, Write, Read
---

# Initialize Canvas Hackathon Deployment

This skill configures your project for deployment to the Canvas hackathon platform.
Run it once at the start of the hackathon. It is safe to re-run — it skips steps that
are already done.

---

## Step 0: Load the deploy target — and stop if there is none

The deploy target lives in `.canvas.config` at the repo root. **There is no default and no fallback.** An unconfigured harness must never push a customer's code to an address nobody chose.

```bash
[ -f .canvas.config ] && . ./.canvas.config
if [ -z "$CANVAS_HOST" ] || [ -z "$CANVAS_DOMAIN" ]; then
  echo "No deploy target configured in .canvas.config — stopping."
  exit 1
fi
echo "Target: $CANVAS_USER@$CANVAS_HOST:$CANVAS_PORT — apps at https://<app>.$CANVAS_DOMAIN"
```

If this stops, **do not guess a host and do not continue.** Tell the user:

> "There is no deploy target configured. Deployment is optional — you can build and run everything locally with `bin/dev`. If this workshop has a deploy target, put it in `.canvas.config` first."

**Throughout this skill, always use the variables** `$CANVAS_USER`, `$CANVAS_HOST`, `$CANVAS_PORT`, `$CANVAS_DOMAIN` — never a literal hostname. To target a different platform, edit `.canvas.config`; do not hand-edit this skill.

---

## Step 1: Find or Generate an SSH Key

Check for an existing public key:

```bash
ls ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
```

**If `id_ed25519.pub` exists** → use it. Continue to Step 2.

**If `id_rsa.pub` exists but not `id_ed25519.pub`** → use `id_rsa.pub`. Continue to Step 2.

**If neither exists**, ask the participant:

> "You don't have an SSH key yet. Would you like me to generate one now, or do you have a
> public key at a different location you'd like to use?"

- If they want to **generate**: run the following, accepting all defaults (no passphrase needed):
  ```bash
  ssh-keygen -t ed25519 -C "canvas-hackathon" -f ~/.ssh/id_ed25519 -N ""
  ```
  Then use `~/.ssh/id_ed25519.pub`.

- If they have a key **at a custom path**: ask them for the path. Read only the `.pub` file.
  Store that path — it will be shown in Step 5.

**CRITICAL: Never read, display, or touch the private key file** (`id_ed25519`, `id_rsa`, or
any file without the `.pub` extension). Only ever work with `.pub` files.

---

## Step 2: Determine the App Name

The app name on the hackathon platform is derived from the current project directory.

```bash
basename "$(pwd)"
```

Normalize the result to a valid Dokku app name:
- Convert to lowercase
- Replace spaces and underscores with hyphens
- Remove any characters that are not alphanumeric or hyphens

For example: `MyApp_v2` → `myapp-v2`, `Task Tracker` → `task-tracker`

Show the participant the derived name and confirm:

> "Your app will be deployed as **`<normalized-name>`** and will be accessible at
> `https://<normalized-name>.$CANVAS_DOMAIN`. Does that look right?
> (Say yes to continue, or tell me a different name.)"

If they provide a different name, apply the same normalization rules to it.

---

## Step 3: Set Up the Git Remote

Check if the `hackathon` remote already exists:

```bash
git remote get-url hackathon
```

If it **already exists** and matches `$CANVAS_HOST`, skip this step.

If it **doesn't exist**, add it:

```bash
git remote add hackathon ssh://dokku@$CANVAS_HOST:2222/<appname>
```

If it exists but points somewhere **different**, remove and re-add:

```bash
git remote remove hackathon
git remote add hackathon ssh://dokku@$CANVAS_HOST:2222/<appname>
```

Verify:

```bash
git remote -v
```

The `hackathon` remote should appear pointing to `ssh://dokku@$CANVAS_HOST:2222/<appname>`.

---

## Step 4: Verify bin/canvas

`bin/canvas` **ships with this harness**. Do not rewrite it — it already reads `.canvas.config`. Just make sure it is executable:

```bash
ls bin/canvas && chmod +x bin/canvas
```

If it is missing, restore it from the harness template rather than writing one from memory.

Verify the connection:

```bash
bin/canvas version
```

This connects to the hackathon Dokku server. A version string like `dokku 0.x.y` confirms access is configured correctly.

Note: this will show `Permission denied (publickey)` until the facilitator has added your SSH key — that is expected at this stage. The connection attempt itself, failing or not, confirms the network path is set up correctly.

---


## Step 5: Verify the /canvas Skill

The `/canvas` skill **ships with this harness** at `.claude/skills/canvas/SKILL.md`. Do not recreate, overwrite or "refresh" it — it reads the deploy target from `.canvas.config`, and any copy written from memory would hardcode the default platform and silently undo that.

Confirm it is in place:

```bash
ls .claude/skills/canvas/SKILL.md && grep -c "CANVAS_DOMAIN" .claude/skills/canvas/SKILL.md
```

Expected: the path, and a count of at least 1. A count of 0 means an outdated copy is installed — restore it from the harness template instead of writing one yourself.

---


## Step 6: Output the Public Key

Read the public key file identified in Step 1:

```bash
cat <path-to-public-key.pub>
```

Display the full contents in a clearly labelled code block, then tell the participant:

---

**Setup complete!** Here is your SSH public key — send this to the hackathon facilitator
to get access to the deployment platform:

```
<full contents of the .pub file>
```

Once the facilitator confirms your key has been added, you can deploy with:

```
/canvas deploy
```

---

Do not summarize what you did. The message above is the entire output of this skill.
