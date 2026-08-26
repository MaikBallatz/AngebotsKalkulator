---
name: init-project
description: Initialize this harness for a specific project. Fills in CLAUDE.md placeholders, creates the Rails app with SQLite, installs Devise, and sets up Tailwind with the design tokens. Run once at the start of a project. Usage: /init-project "what you're building" OR /init-project path/to/requirements.md
disable-model-invocation: true
user-invocable: true
---

# Initialize Project

You are setting up a new Rails project from the hackathon harness. This skill runs once and produces a fully working app ready for feature development.

## Pre-flight: Verify Ruby Version

Before doing anything else, check that the correct Ruby is active:

```bash
ruby -v
```

It must show the version from `.ruby-version`. If it shows `2.6.x` (the macOS system Ruby), stop and tell the user:

> "The correct Ruby version isn't active. Please run `/init-dependencies` first — it installs rbenv and the Ruby this project needs, and wires the shims into `~/.zshenv` so every shell finds them. After it completes, close this conversation and start a new one, then run `/init-project` again."

---

## Step 1: Parse the Input

The argument is either a description string or a file path.

- If it looks like a file path (contains `/` or ends in `.md`, `.txt`, etc.), read that file.
- Otherwise treat the argument as the domain description directly.

If no argument was given, ask:
> "What are you building? Describe it in one sentence, e.g. `/init-project \"A task tracker for small teams\"`"

---

## Step 2: Analyze the Domain

Before editing anything, reason through these questions:

1. **App name** — short PascalCase name suitable as a Ruby module (e.g., `TaskFlow`, `EventHub`, `BudgetPal`)
2. **One-line description** — what it does and for whom
3. **Core entities** — the main "things" this app manages
4. **User ownership hierarchy** — which entities does a User directly own? Which are owned transitively?
5. **Core features** — 4–6 main capability areas
6. **Primary user workflow** — what is the main thing a user comes here to do?

Questions 5 and 6 are reasoning only — they sharpen your understanding of the domain but do **not** get written into `CLAUDE.md`. They belong to `requirements.md`, which `/grill` writes from what the team tells it and then hardens with them. Do not write `requirements.md` in this skill — and do not tell the team to fill it by hand. Leaving the placeholders in place is what makes `/grill` interview the team's intent instead of your guess.

---

## Step 3: Fill CLAUDE.md Placeholders

`CLAUDE.md` is the **HOW** — only five things in it are project-specific: the title line, three blocks in **Part 1**, and one bullet in Part 2's testing section. The **WHAT** (features, workflows, scope cuts) belongs in `requirements.md` and must NOT be duplicated into `CLAUDE.md`.

Read `CLAUDE.md`. Replace every `[PLACEHOLDER: ...]` tag with real content:

**1. Title line** (first line of the file — keep the ` - ` separator, it is parsed in Step 4):
```
# {AppName} - {Short Domain Description}
```

**2. Part 1 → "What we're building":**
Write 2–3 sentences describing what the app does and who it's for. Keep it short — this is orientation, not a spec. Do not list features here.

**3. Part 1 → "Ownership model":**
Write the actual hierarchy, e.g. `User → Projects, User → Tags, Project → Tasks`.

**4. Part 1 → "Scoping every query":**
Replace the placeholder list with 4–5 real examples using actual model names:
```
- Projects: `current_user.projects` (never `Project.all` or `Project.find`)
- Tasks (via Project): `Task.for_user(current_user)`
- Building: `current_user.projects.new(...)`
- Finding: `current_user.projects.find(params[:id])` — raises 404 if not owned
```

**5. Part 2 → "Testing (RSpec)", last bullet:**
Replace the placeholder with the actual names of the top-level user-owned resources.

After filling, verify no `[PLACEHOLDER` tags remain:
```bash
grep -n "\[PLACEHOLDER" CLAUDE.md
```

If any remain, fill them before proceeding.

Leave Parts 2–5 untouched. Part 5 ("Rules we learned") stays empty except for its example line — the team fills it during the build.

---

## Step 4: Install Dependencies

**This must run before `rails new`.** Verified 2026-08-04 on a machine without the gems preinstalled: `bundle exec rails new` fails with `Could not find gem 'rails (~> 8.0)' in locally installed gems (Bundler::GemNotFound)`. `/init-dependencies` installs Ruby and Bundler — not Rails. Rails comes from this Gemfile, so it has to be installed first.

```bash
bundle install
```

Use plain `bundle`, **not** `bin/bundle` — the binstubs don't exist until Step 6.

If this fails because `bundle` resolves to the system Ruby 2.6, the shell has no usable Ruby on PATH. On an rbenv machine, use the absolute path once — Bundler ships as a default gem and lives under `versions/`, next to the ruby itself:

```bash
"$HOME/.rbenv/versions/$(cat .ruby-version)/bin/bundle" install
```

Do not hardcode that path anywhere else — it only exists on rbenv installations. (Historical note: the earlier rvm-era fallback pointed at `~/.rvm/gems/…/bin/bundle`, which does not exist for a default gem — that path failed with exit 127 in a real session.)

---

## Step 5: Run `rails new`

Extract the app name set in Step 3 (from the first line of CLAUDE.md).

Validate it is PascalCase with no spaces — if the user gave a name with spaces, convert to PascalCase and confirm with them.

**Back these three up first — `rails new . --force` overwrites them.** Verified 2026-08-04: despite `--skip-gemfile`, `--force` replaces the `Gemfile` and the `README.md` with Rails' stock versions, and writes its own `Gemfile.lock`. Every other harness file survives untouched.

```bash
cp Gemfile Gemfile.bak
cp README.md README.md.bak
cp Gemfile.lock Gemfile.lock.bak
```

Now generate the app. The name flag is `--name` — **not** `--app-name`, which Rails silently ignores (it would take the name from the folder instead):

```bash
bundle exec rails new . \
  --name={AppName} \
  --database=sqlite3 \
  --force \
  --skip-git \
  --skip-bundle \
  --skip-gemfile
```

Immediately restore all three (note the direction — `.bak` goes back to the real name):

```bash
mv Gemfile.bak Gemfile
mv README.md.bak README.md
mv Gemfile.lock.bak Gemfile.lock
```

Verify the restore worked before continuing:

```bash
ls Gemfile* README.md* && grep -c "tailwindcss-rails" Gemfile && head -1 README.md
```

Expected: no `.bak` files left, `1` for the grep, and `# Hackathon Rails Harness` as the first README line. A stock Rails README or a `0` means the restore didn't run — fix it now. Left alone, the participant loses the harness instructions and every gem the harness depends on.

The restored `Gemfile.lock` matches the restored `Gemfile`, and the gems from Step 4 are already installed — no second `bundle install` is needed.

### Configure the generators once, centrally

In `config/application.rb`, **directly below the `config.load_defaults` line** (same placement rule as the Active Storage line in Step 8 — above it, `load_defaults` silently overwrites):

```ruby
# No placeholder specs, no fixtures. Every generated pending spec reads as
# "broken" to someone who cannot read a backtrace, and request specs are
# written by hand — the TDD cycle demands it.
config.generators do |g|
  g.test_framework :rspec, helper_specs: false, view_specs: false,
                            routing_specs: false, request_specs: false
  g.fixtures false
end
```

This replaces a whole class of per-call cleanup: every `generate controller` used to write a request spec that called a route which does not exist. One block here, and the controller generators stay quiet for the rest of the project.

**Model specs have no such switch** — `model_specs:` looks plausible and does nothing (verified 2026-08-12: the pending spec appeared anyway). Model generation happens during the build, so the rule lives in `.claude/rules/database.md`, which loads exactly then.

If `rails new` fails, restore the three files and stop.

---

## Step 6: Generate Binstubs

**Do not use `bundle binstubs railties`.** It writes a Bundler-flavoured `bin/rails` that Rails refuses to use for generators — every `bin/rails generate ...` then prints a "your binstub was generated by Bundler" lecture instead of running. Verified 2026-08-04.

Let Rails write its own binstubs, then add only the one Rails doesn't provide:

```bash
bundle exec rails app:update:bin
bundle binstubs rspec-core --force
```

Verify — the first command must print a path, the second must succeed:

```bash
ls bin/rspec && grep -q APP_PATH bin/rails && echo "bin/rails is a Rails binstub"
```

If the `grep` fails, `bin/rails` is the Bundler version: re-run `bundle exec rails app:update:bin` before continuing. Generators will not work until this is right.

### Fix binstub shebang lines

Binstubs start with `#!/usr/bin/env ruby`, which resolves via PATH. With the `~/.zshenv` shims entry from `/init-dependencies` that resolves correctly — the pinning below is the second line of defence for shells where it does not (a skipped setup, a broken profile). The kernel reads a pinned shebang directly; PATH is never consulted.

**Loop over every Ruby binstub, not a fixed list** — `bin/setup`, `bin/dev` and whatever future Rails versions add are Ruby scripts too, and a fixed list silently misses them. **Only when rbenv is actually installed:** on asdf, mise or a system Ruby the rbenv path does not exist, and rewriting to it breaks every working binstub.

```bash
RUBY_BIN="$HOME/.rbenv/versions/$(cat .ruby-version)/bin/ruby"
if [ -x "$RUBY_BIN" ]; then
  for f in bin/*; do
    if [ -f "$f" ] && head -1 "$f" | grep -q '^#!/usr/bin/env ruby$'; then
      perl -pi -e "s|^#!/usr/bin/env ruby$|#!${RUBY_BIN}|" "$f"
    fi
  done
  echo "shebangs pinned to rbenv ruby"
else
  echo "rbenv not found — leaving shebangs on PATH (correct for asdf/mise/system ruby)"
fi
```

`perl -pi -e`, not `sed -i ''` — the latter is BSD-only and fails under WSL. `perl` ships with macOS and every Ubuntu install.

Verify: `head -1 bin/rails`

**If anything here misbehaves**, read `ruby-path.md` next to this file — it explains why Claude Desktop loses the Ruby path, how to repair binstubs by hand, and why this fix must not travel to a server.

---

## Step 7: Set Up RSpec

```bash
bin/rails generate rspec:install
```

Add both helper modules to `spec/rails_helper.rb`. Find the `RSpec.configure` block and add:

```ruby
config.include FactoryBot::Syntax::Methods
config.include Devise::Test::IntegrationHelpers, type: :request
config.example_status_persistence_file_path = "spec/examples.txt"
```

**The third line is what lets the flow page answer "läuft es noch?"** After every run RSpec writes each example's status to `spec/examples.txt`, and `/flow` reads it — no gem, no coverage tooling, no second run. Without it the page can only say the tests have never run.

**The second line is not optional.** `CLAUDE.md` tells you to write `sign_in user, scope: :user` in request specs; without this include, `sign_in` does not exist and the first spec for any logged-in feature dies with `NoMethodError`. That failure looks exactly like a planned RED step but is a configuration error — the worst kind of red for a team that cannot read the backtrace.

Verify:

```bash
grep -c "IntegrationHelpers" spec/rails_helper.rb
```

**The user factory does not belong here.** It is written in Step 9, after Devise runs — see the warning there.

---

## Step 8: Set Up the Database and File Storage

```bash
bin/rails db:create
bin/rails active_storage:install
bin/rails db:migrate
```

**Why Active Storage is installed even though nothing uses it yet.** Sooner or later a team wants to attach something — a CV, a photo, a contract. Installed up front it is a five-minute feature (`has_one_attached`, a file field, a download link). Retrofitted at 15:00 on day two it is a migration, a restart and a lost hour. It costs one migration and nothing else.

**Do not add `image_processing` or any variant/thumbnail code.** That path needs `vips` or ImageMagick on the machine, and a missing system library is exactly the invisible break the icon rule exists to avoid. Upload, list, download — that is the whole feature. Storage stays on local disk, which is already the default.

**Say so in the config, or Rails keeps asking.** In `config/application.rb`, **directly below the `config.load_defaults` line**:

```ruby
# No thumbnails in this harness — see design-system.md.
config.active_storage.variant_processor = :disabled
```

Verify, because the position matters:

```bash
bin/rails runner "puts Rails.application.config.active_storage.variant_processor.inspect"
```

Expected: `:disabled`. If it prints `:vips`, the line landed **above** `config.load_defaults`, which then overwrote it — verified 2026-08-12. Move it below and check again.

Without this, `log/development.log` carries *"Generating image variants require the image_processing gem"* on every boot, even though nothing attaches an image. Harmless, but it is exactly the kind of line a participant reads as a broken setup — and the fix makes our no-thumbnails decision explicit rather than accidental.

---

## Step 9: Install Devise

```bash
bin/rails generate devise:install
```

This will print instructions. Follow step 2 only — and **check before adding**: Rails 8.1 already generates the line in `config/environments/development.rb`. Add it only if missing, or you end up with two:
```bash
grep -q "action_mailer.default_url_options" config/environments/development.rb || \
  echo 'add config.action_mailer.default_url_options = { host: "localhost", port: 3000 } inside the configure block'
```

Generate the User model:
```bash
bin/rails generate devise User
bin/rails db:migrate
```

**Then clean up after the generator — both of these, in this order:**

```bash
rm -f spec/models/user_spec.rb
```

```ruby
# spec/factories/users.rb — write this AFTER the generator, never before
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
  end
end
```

Verify:

```bash
ls spec/models/ 2>/dev/null; grep -c "password123" spec/factories/users.rb
```

Expected: nothing from the first command, `1` from the second.

**Why both, verified 2026-08-12 in a full dry run:**

- The generator writes `spec/models/user_spec.rb` with a single `pending` marker. Left in place, the team's first `bin/rspec` reports `1 pending` — and for someone who cannot read a backtrace, "pending" is indistinguishable from "broken". The first run must say green and nothing else. When the team writes real User specs later, the file comes back on its own terms.
- The generator also **overwrites `spec/factories/users.rb` with an empty factory** — it prints `force spec/factories/users.rb` and replaces the body with nothing. Written earlier, the email and password silently disappear. The next spec that calls `create(:user)` then dies on a Devise validation, which looks like a broken test and is a setup error. Write the factory here, after the generator, and it survives.

---

## Step 10: Set Up Tailwind and the Design Tokens

```bash
bin/rails tailwindcss:install
```

### Write the design tokens

**Not optional.** Every component in `design-system.md` is built from these tokens — without the `@theme` block the classes do not exist and the app renders unstyled.

Copy the shipped defaults into place:

```bash
cp .claude/skills/init-project/templates/tailwind-theme.css app/assets/tailwind/application.css
grep -c "color-brand-600" app/assets/tailwind/application.css
```

Expected: `1`. If `tailwindcss:install` created the stylesheet elsewhere, find it with `find app/assets -name "*.css"` and copy there instead.

These are the neutral harness defaults and reproduce the standard look exactly. **Do not guess brand colors here** — a customer's corporate design is applied later with `/design-system`.

---

## Step 11: Verify Procfile.dev, replace bin/dev

**Verify, don't create:** `tailwindcss:install` (Step 10) already writes `Procfile.dev` with exactly these two lines — creating it again is duplicate work that can drift. Check:

```bash
grep -c "bin/rails server\|tailwindcss:watch" Procfile.dev
```

Expected: `2`. Only if the file is missing or different, write it:
```
web: bin/rails server
css: bin/rails tailwindcss:watch
```

**Replace `bin/dev` with the Ruby version** — the stock file is an `sh` script that calls `gem` and `foreman` through PATH, and on a machine without the shims wired it finds the system Ruby's gem and dies ("incompatible library version", then `foreman: not found`). The Ruby version resolves everything inside the running interpreter and gets pinned by the shebang loop in Step 6:

```bash
cp .claude/skills/init-project/templates/bin-dev.rb bin/dev
chmod +x bin/dev
```

(The shebang loop already ran in Step 6 — pin this one file now, same guard as there: only if `$HOME/.rbenv/versions/$(cat .ruby-version)/bin/ruby` exists.)

---

## Step 12: Update the Application Layout

Read `app/views/layouts/application.html.erb` and replace the entire `<body>` element — keep `<head>` unchanged — with the contents of:

`.claude/skills/init-project/templates/layout-body.html.erb`

Then substitute `{AppName}` in it with the real app name from Step 3. Every class in that file comes from `design-system.md`; do not introduce raw colors.

Also ensure the stylesheet is in the `<head>`:

```erb
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```

Verify:

```bash
grep -c "bg-page" app/views/layouts/application.html.erb && grep -c "PLACEHOLDER\|{AppName}" app/views/layouts/application.html.erb
```

Expected: `1` then `0`. A `1` on the second means the app name was not substituted.

---

## Step 13: Add a Real Home Page

**Do not use `root "rails/welcome#index"`.** `Rails::WelcomeController` declares `layout false` (verified in the railties source), so the layout you just built in Step 12 — app name, navigation, sign-up button — is not rendered at all. The participant would spend the morning installing and then be greeted by the generic "Yay! You're on Rails" page, with no visible way to register. That is the one moment of the morning that should pay them back.

Generate a minimal home page instead:

```bash
bin/rails generate controller Home index --skip-routes
```

No `--no-*-specs` flags needed — the generator block from Step 5 already suppresses helper, view, routing and request placeholder specs. (The reason that block exists: every generated pending spec reads as *broken* to someone who cannot read a backtrace, and the first run must be green with nothing else on screen — after Step 14 that means `3 examples, 0 failures`.)

Set the route in `config/routes.rb`:

```ruby
# Your first real resource replaces this later.
root "home#index"
```

And give the Home controller the line every app of this shape ends up needing — commented out, as a signpost. The first real feature is almost always a list or dashboard, and signed-in users should land there instead of on the sign-up pitch:

```ruby
class HomeController < ApplicationController
  def index
    # Sobald es eine eigene Startseite für Angemeldete gibt:
    # redirect_to interviews_path if user_signed_in?
  end
end
```

Replace `app/views/home/index.html.erb` with four lines built from the component table in `design-system.md` — nothing invented, only tokens:

```erb
<div class="bg-surface rounded-card shadow p-6">
  <h1 class="text-2xl font-bold text-ink">{AppName}</h1>
  <p class="text-sm text-ink-muted mt-2">{one-line description from Part 1}</p>
  <div class="mt-6">
    <%= link_to "Los geht's", new_user_registration_path,
          class: "bg-brand-600 hover:bg-brand-700 text-brand-ink font-medium py-2 px-4 rounded-control" %>
  </div>
</div>
```

Substitute `{AppName}` and the description with the real values from Step 3.

**Write the request spec by hand** — `spec/requests/home_spec.rb` (the generator no longer creates one; `request_specs: false` from Step 5):

```ruby
require "rails_helper"

RSpec.describe "Home", type: :request do
  it "shows the app name" do
    get root_path
    expect(response).to have_http_status(:ok)
  end
end
```

This page is also the proof that the design tokens work: when `/design-system` runs later, its colours change in front of the team.

---

## Step 14: Add the Two Reference Pages

Two routes the team does not build and never has to maintain: `/design` shows what the app is made of, `/flow` shows what it does. Both are generated here, once.

### 14a — The design page

A second route, `/design`, showing every component from `design-system.md` with the current tokens — and each token's **name** next to it.

**Why this page exists.** The design system is otherwise invisible: it lives in a CSS file and only reveals itself feature by feature. A participant who cannot see it cannot judge it, and cannot name what bothers them. With the token names on screen, "make it friendlier" becomes "brand-600 is too loud" — a sentence `/design-system` can act on.

Generate the controller:

```bash
bin/rails generate controller Design index --skip-routes
```

Add the route in `config/routes.rb`, below `root`:

```ruby
get "design", to: "design#index"
```

Copy the page into place — it needs no edits, no app name, no substitutions:

```bash
cp .claude/skills/init-project/templates/styleguide.html.erb app/views/design/index.html.erb
```

Write `spec/requests/design_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Design", type: :request do
  it "renders the design system page" do
    get "/design"
    expect(response).to have_http_status(:ok)
  end
end
```

Verify:

```bash
grep -c "brand-600" app/views/design/index.html.erb && bin/rspec
```

Expected: a count above zero, then `2 examples, 0 failures` — the third comes with 14b.

**Do not link it from the main navigation.** It is a reference, not part of the app being built — a nav entry the team did not ask for is confusing in their own demo. The address is enough.

**Do not translate or restyle it per project.** It is customer-neutral and identical everywhere; that is what makes it a reliable reference.

### 14b — The flow page

`/flow` draws the primary workflow from `requirements.md` as boxes and arrows.

**Why it is a page and not a diagram in the chat.** `/grill` writes the workflow as a mermaid block, which is the right machine-readable form — but **mermaid does not render in Claude Desktop's Code tab** (anthropics/claude-code#52517, open since 2026-04-23). The team would see raw source, which is worse than the prose it replaced. The browser is where they already look, and boxes with arrows need no library at all.

```bash
bin/rails generate controller Flow index --skip-routes
```

Route, below the design one:

```ruby
get "flow", to: "flow#index"
```

Both files come from templates and need no edits:

```bash
cp .claude/skills/init-project/templates/flow_controller.rb app/controllers/flow_controller.rb
cp .claude/skills/init-project/templates/flow.html.erb app/views/flow/index.html.erb
```

Write `spec/requests/flow_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Flow", type: :request do
  it "renders the workflow page while requirements are still empty" do
    get "/flow"
    expect(response).to have_http_status(:ok)
  end
end
```

Verify — the page must render **before** anyone has written a requirement, showing its empty state:

```bash
bin/rspec
```

Expected: `3 examples, 0 failures`.

**The suite proves the page renders, not that it says the truth.** Both templates are copied unchanged, so there is nothing to check by hand — but if you ever edit `app/views/flow/index.html.erb`, the rule in its header comment applies: no step number, label or count written by hand. That class of error returns 200 and passes every test.

**The empty state is the point, not a fallback.** Until `/grill` runs, the page says *"Der Hauptweg steht noch nicht — sag `/grill`."* That turns an empty page into the next instruction.

---

## Step 15: Verify

```bash
bin/rails --version
bin/rspec --version
```

Both should return version strings.

Run a quick check that the app boots:
```bash
bin/rails runner "puts 'App boots OK'"
```

---

## Step 16: Create the Baseline Commit

`rails new` ran with `--skip-git`, so nothing is under version control yet. **This is the safety net for the whole workshop** — without a commit there is no way back when a build goes sideways at 17:00.

```bash
git rev-parse --git-dir >/dev/null 2>&1 || git init
git add -A
git commit -m "chore: harness baseline — working setup before any feature"
```

Then tell the team, in these words:

> "Everything is saved. From here on, whenever the tests are green, say **'sicher das ab'** and I'll make a restore point. If something goes wrong later, say **'zurück zum letzten sicheren Stand'** and we're back here."

Commit at every green state from now on. A restore point nobody made is the most expensive missing line in a two-day build.

---

## Step 17: Report

Tell the user:

1. **Configured as**: `{AppName}` — {one-line description}
2. **Rails version**: (from step 15)
3. **Database**: SQLite, created and migrated — Active Storage ready, so attachments are a five-minute feature whenever they come up
4. **Auth**: Devise installed, User model created
5. **Design**: neutral default tokens written to `app/assets/tailwind/application.css` — the corporate design comes later, on day 2
6. **Next steps**:
   - Start the dev server: `bin/dev`
   - Open http://localhost:3000 — your app
   - Open http://localhost:3000/design — **your building blocks.** Every button, form and table the app will ever use, in the neutral default. Worth thirty seconds now; it is what your corporate design will transform later.
   - Open http://localhost:3000/flow — **your main path.** Empty for now; `/grill` fills it in the next step, and from then on it shows what the app has to do, end to end.
   - **Say `/grill`** — he listens first, writes `requirements.md` from what you tell him, then sharpens it with you, one question at a time. You do not fill anything in by hand.
   - Only then ask for a plan. Building before the WHAT is clear is the most expensive mistake in a two-day build.
   - Remember to replace the root route in `config/routes.rb` when you create your first controller
