---
name: canvas
description: Deploy your app and manage backing services on the Canvas hackathon platform. Usage: /canvas deploy | /canvas add postgres | /canvas add redis | /canvas logs | /canvas open
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash, Read, Edit, Write
---

# Canvas — Deploy and Manage Your App

This skill deploys your app to the Canvas hackathon platform and manages its backing
services (PostgreSQL database, Redis cache).

The app name comes from the git remote you set up during init; the deploy target comes from `.canvas.config`:

```bash
[ -f .canvas.config ] && . ./.canvas.config
: "${CANVAS_DOMAIN:=$CANVAS_DOMAIN}"
git remote get-url hackathon
```

Extract the app name: everything after the last `/` in that URL.
Extract the app URL: `https://<appname>.$CANVAS_DOMAIN`.

> Wherever this skill shows `$CANVAS_DOMAIN`, substitute `$CANVAS_DOMAIN` from `.canvas.config`. To target a different platform, edit `.canvas.config` — don't hand-edit this skill.

If the `hackathon` remote is missing, stop and tell the participant to run `/init-hackathon-canvas` first.

---

## Understand the Intent

Read `` and map it to one of these actions:

| Intent | Action |
|--------|--------|
| `deploy`, `push`, `ship`, `release`, or empty | → **Deploy** |
| `add postgres`, `add database`, `postgresql`, `initialize postgres` | → **Add PostgreSQL** |
| `add redis`, `add cache`, `initialize redis` | → **Add Redis** |
| `logs` | → **Show Logs** |
| `open`, `url` | → **Show URL** |
| `status`, `ps` | → **Show Status** |
| `config`, `env` | → **Show Config** |
| anything else | → **Show Help** |

---

## Action: Deploy

### 1. Ensure there is at least one commit

```bash
git log --oneline -1
```

If empty, tell the participant to make a first commit before deploying:
> "You need at least one commit before deploying. Stage your files with `git add .` and commit with `git commit -m 'initial commit'`."

### 2. Ensure deployment configuration exists

Check if a `Procfile` or `Dockerfile` exists in the project root:

```bash
ls Procfile Dockerfile
```

**If neither exists**, detect the project type and create a `Procfile`:

- **Rails** (has `config/application.rb`):
  ```
  web: bundle exec puma -C config/puma.rb
  ```

- **Node.js** (has `package.json` with a `start` script):
  ```
  web: npm start
  ```

- **Python** (has `requirements.txt` or `pyproject.toml`):
  ```
  web: gunicorn app:app
  ```
  Also check for a `wsgi.py` or `asgi.py` and adjust accordingly.

- **Unknown**: ask the participant what command starts their web server.

After creating `Procfile`, commit it:
```bash
git add Procfile
git commit -m "add Procfile for Dokku deployment"
```

### 3. Ensure the app exists on the platform

```bash
bin/canvas apps:list
```

If `<appname>` is not in the list, create it:

```bash
bin/canvas apps:create <appname>
```

### 4. Set SECRET_KEY_BASE (Rails only)

Only if the project is a Rails app. Check if it is already set:

```bash
bin/canvas config:show <appname>
```

If `SECRET_KEY_BASE` is not in the output, generate and set it:

```bash
bin/canvas config:set <appname> SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### 5. Push

```bash
git push hackathon HEAD:main
```

If the push fails with "rejected" because of a non-fast-forward, tell the participant:
> "The remote has changes your local branch doesn't. This shouldn't normally happen on a
> hackathon project — run `git push hackathon HEAD:main --force` if you're sure you want to overwrite."

Do not force-push automatically.

### 6. Run database migrations (Rails only)

If the project is Rails and PostgreSQL has been linked (check `bin/canvas config:show <appname>` for `DATABASE_URL`):

```bash
bin/canvas run <appname> rake db:migrate
```

### 7. Show the result

```
✅ Deployed!

Your app is live at: https://<appname>.$CANVAS_DOMAIN

The platform uses basic auth during the hackathon — ask your facilitator for the password.
```

---

## Action: Add PostgreSQL

### 1. Check if already linked

```bash
bin/canvas config:show <appname>
```

If `DATABASE_URL` is already set, tell the participant:
> "PostgreSQL is already linked to your app — `DATABASE_URL` is set. No action needed."

### 2. Create and link the database

```bash
bin/canvas postgres:create <appname>-db
bin/canvas postgres:link <appname>-db <appname>
```

Dokku now injects `DATABASE_URL` into your app automatically.

### 3. Adapt the codebase

Detect the project type and update it to use `DATABASE_URL`:

**Rails:**

a. Check if `gem 'pg'` is in `Gemfile`. If not, add it (keep `gem 'sqlite3'` too — SQLite for dev, PostgreSQL for production):
   Open `Gemfile` and add after the sqlite3 line:
   ```ruby
   gem "pg", group: :production
   ```

b. Run:
   ```bash
   bin/bundle install
   ```

c. Check `config/database.yml`. In the `production:` section, ensure it reads from `DATABASE_URL`:
   ```yaml
   production:
     adapter: postgresql
     encoding: unicode
     pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
     url: <%= ENV["DATABASE_URL"] %>
   ```
   Replace the existing production section with the above.

d. Commit:
   ```bash
   git add Gemfile Gemfile.lock config/database.yml
   git commit -m "configure PostgreSQL for production via DATABASE_URL"
   ```

**Node.js:** No code changes needed — `process.env.DATABASE_URL` is available in your app.
Tell the participant the env var name and format: `postgres://user:pass@host:port/dbname`.

**Python:** No code changes needed — `os.environ['DATABASE_URL']` is available.
Tell the participant the env var name.

### 4. Redeploy and migrate

```bash
git push hackathon HEAD:main
bin/canvas run <appname> rake db:migrate
```

(Skip the migrate step for non-Rails apps.)

### 5. Confirm

```
✅ PostgreSQL linked!

DATABASE_URL is now available to your app in production.
Your database was created and migrations have been run.

App URL: https://<appname>.$CANVAS_DOMAIN
```

---

## Action: Add Redis

### 1. Check if already linked

```bash
bin/canvas config:show <appname>
```

If `REDIS_URL` is already set, tell the participant it's already linked.

### 2. Create and link Redis

```bash
bin/canvas redis:create <appname>-cache
bin/canvas redis:link <appname>-cache <appname>
```

Dokku now injects `REDIS_URL` into your app automatically.

### 3. Adapt the codebase

**Rails:**

a. Check if `gem 'redis'` is in `Gemfile`. If not, add it:
   ```ruby
   gem "redis"
   ```

b. Run:
   ```bash
   bin/bundle install
   ```

c. To use Redis for Rails caching, add to `config/environments/production.rb`:
   ```ruby
   config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
   ```

d. Commit:
   ```bash
   git add Gemfile Gemfile.lock config/environments/production.rb
   git commit -m "configure Redis for production caching via REDIS_URL"
   ```

**Node.js / Python:** No code changes needed — `REDIS_URL` is available as an env var.
Tell the participant the env var name and format: `redis://user:pass@host:port`.

### 4. Redeploy

```bash
git push hackathon HEAD:main
```

### 5. Confirm

```
✅ Redis linked!

REDIS_URL is now available to your app in production.

App URL: https://<appname>.$CANVAS_DOMAIN
```

---

## Action: Show Logs

```bash
bin/canvas logs <appname> -t
```

This streams live logs. Tell the participant to press Ctrl+C to stop.

---

## Action: Show URL

```
Your app: https://<appname>.$CANVAS_DOMAIN

The platform uses basic auth during the hackathon — ask your facilitator for the password.
```

---

## Action: Show Status

```bash
bin/canvas ps:report <appname>
```

---

## Action: Show Config

```bash
bin/canvas config:show <appname>
```

---

## Action: Show Help

```
Available canvas commands:

  /canvas deploy              — push your code and go live
  /canvas add postgres        — provision a PostgreSQL database
  /canvas add redis           — provision a Redis cache
  /canvas logs                — stream live app logs
  /canvas open                — show your app URL
  /canvas status              — show running containers
  /canvas config              — show environment variables

Your app URL: https://<appname>.$CANVAS_DOMAIN
```
