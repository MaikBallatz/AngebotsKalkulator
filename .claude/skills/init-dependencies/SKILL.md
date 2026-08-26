---
name: init-dependencies
description: Set up a fresh machine for Rails development. Installs Homebrew (macOS), rbenv + ruby-build, the Ruby version from .ruby-version, and Bundler. Safe to re-run — skips steps that are already done. Usage: /init-dependencies
disable-model-invocation: true
user-invocable: true
---

# Initialize Development Dependencies

Set up everything needed to run a Rails app on a fresh machine. Each step checks whether the tool is already installed before doing anything — safe to re-run.

<!--
2026-08-12: rewritten from rvm to rbenv + ruby-build. rvm has had no release
since 2021, and a real session on a fresh Mac (11.08., LernCoach build) hit
three blockers that all traced back to that age: GPG verification against a
dead keyserver, autolibs demanding the removed openssl@1.1, and a PATH recipe
that macOS's path_helper silently defeated. rbenv removes all three classes.
-->

## Step 0: Read the Ruby version and detect the OS

**The version lives in `.ruby-version`, nowhere else.** Read it first:

```bash
RUBY_V=$(cat .ruby-version)
echo "Installing Ruby ${RUBY_V}"
```

If the file does not exist, stop: you are not in the project folder. Tell the user to open Claude in the project folder (QUICKSTART Schritt 2) and run `/init-dependencies` again. Do not guess a version.

Then run `uname -s`:
- `Darwin` → macOS path
- `Linux` → Linux path
- Anything else (including Windows CMD/PowerShell output) → Windows path

---

## Windows Path

Ruby tooling does not run natively on Windows. Print this message and stop:

```
============================================================
  Windows detected — Rails development requires WSL2
============================================================

1. Open PowerShell as Administrator and run:
     wsl --install

2. Reboot your computer.

3. Open the "Ubuntu" app that was installed.

4. Inside the Ubuntu terminal, open Claude Code and run /init-dependencies again.
   It will follow the Linux path from there.

For help with WSL2: https://docs.microsoft.com/en-us/windows/wsl/install
============================================================
```

---

## macOS Path

### Step 1: Install Homebrew (if missing)

Check: `which brew`

If not found:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After install, add Homebrew to PATH. Apple Silicon Macs install it at `/opt/homebrew`, which is not on the default PATH. Write to both `~/.zprofile` (login shells) and `~/.zshenv` (all shells, including the non-interactive tool shell of Claude Code):
```bash
grep -qF 'brew shellenv' ~/.zprofile 2>/dev/null || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
grep -qF 'brew shellenv' ~/.zshenv 2>/dev/null || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshenv
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Skip the above if `brew --version` already works (Intel Macs install to `/usr/local/bin` which is already on PATH).

Verify: `brew --version` should print a version string.

### Step 2: Install rbenv, ruby-build and the libraries Ruby needs

```bash
brew install rbenv ruby-build libyaml openssl@3
```

Check first with `brew list --versions rbenv ruby-build` — anything already listed is skipped by brew, so re-running is harmless. (`--versions` matters: a bare `brew list openssl` prints every file of the package, ~600 KB of output.)

No GPG keys, no signature ceremony — brew verifies its own bottles. ruby-build finds Homebrew's OpenSSL by itself; there is no `--with-openssl-dir` and no autolibs.

### Step 3: Wire rbenv into the shell — three files, each for a different reason

This is the step that decides whether tomorrow's terminal still works. macOS runs zsh, and zsh reads its config in a specific order — a single entry is not enough:

```bash
# 1. ~/.zshenv — read by EVERY zsh, including non-interactive ones.
#    This is what makes `ruby` resolve correctly inside Claude Code's tool shell.
grep -qF '.rbenv/shims' ~/.zshenv 2>/dev/null || \
  echo 'export PATH="$HOME/.rbenv/shims:$PATH"' >> ~/.zshenv

# 2. ~/.zshrc — interactive shells get the full rbenv integration.
grep -qF 'rbenv init' ~/.zshrc 2>/dev/null || \
  echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

# 3. ~/.zprofile, at the END — login shells run /etc/zprofile (path_helper)
#    AFTER ~/.zshenv, and path_helper pushes /usr/bin back in front of the
#    shims. Re-exporting here wins that race. Without this line, every new
#    Terminal window shows the system Ruby 2.6 again, even though the
#    installation succeeded.
grep -qF '.rbenv/shims' ~/.zprofile 2>/dev/null || \
  echo 'export PATH="$HOME/.rbenv/shims:$PATH"' >> ~/.zprofile
```

Then activate for the current session:
```bash
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - zsh)" 2>/dev/null || true
```

### Step 4: Install Ruby

Check: `rbenv versions | grep "$RUBY_V"`

If not listed:
```bash
rbenv install "$RUBY_V"
rbenv global "$RUBY_V"
rbenv rehash
```

This compiles Ruby from source — **15 to 25 minutes** of scrolling compiler output. That is normal, not stuck.

Verify: `ruby -v` should show the version from `.ruby-version`.

### Step 5: Install Bundler

Check: `gem list bundler | grep bundler`

If not listed:
```bash
gem install bundler
rbenv rehash
```

Verify: `bundle -v` should print a version string.

---

## Linux Path

### Step 1: Install build dependencies

For apt-based systems (Ubuntu, Debian — and therefore WSL):
```bash
sudo apt-get update
sudo apt-get install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev
```

For yum/dnf-based systems (Fedora, RHEL, CentOS):
```bash
sudo dnf install -y curl git gcc gcc-c++ make openssl-devel readline-devel zlib-devel libyaml-devel
```

Detect which package manager to use by checking `which apt-get` vs `which dnf`.

### Step 2: Install rbenv + ruby-build (if missing)

Check: `[ -d "$HOME/.rbenv" ]`

If not found, use the official installer (clones rbenv and ruby-build from GitHub — no GPG, no keyserver):
```bash
curl -fsSL https://raw.githubusercontent.com/rbenv/rbenv-installer/HEAD/bin/rbenv-installer | bash
```

**Wire it into the shell files this system actually reads.** Ubuntu (and therefore WSL) runs **bash**, not zsh — a line in `~/.zshenv` is never read there. The `grep` guard makes re-runs safe:

```bash
for rc in ~/.bashrc ~/.profile; do
  grep -qF '.rbenv/bin' "$rc" 2>/dev/null || \
    printf '%s\n%s\n' 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"' 'eval "$(rbenv init - bash)"' >> "$rc"
done
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)"
```

### Step 3: Install Ruby

```bash
rbenv install "$RUBY_V"
rbenv global "$RUBY_V"
rbenv rehash
```

Compiling takes 15–25 minutes. Verify: `ruby -v` shows the version from `.ruby-version`.

### Step 4: Install Bundler

```bash
gem install bundler
rbenv rehash
```

Verify: `bundle -v` should print a version string.

---

## Final Verification — in FRESH shells, not this one

The current shell has everything sourced by hand, so `ruby -v` here proves nothing — the classic failure is an installation that works in this window and is gone in the next. Test the shells a participant will actually get:

macOS:
```bash
zsh -ilc 'ruby -v'   # fresh interactive login shell (a new Terminal window)
zsh -lc  'ruby -v'   # fresh non-interactive shell (Claude Code's tool shell)
```

Linux/WSL:
```bash
bash -ilc 'ruby -v'
bash -lc  'ruby -v'
```

**Both must show the version from `.ruby-version`.** If one of them shows 2.6.x (macOS system Ruby) or "command not found", the corresponding shell file from Step 3 did not take — fix that now, not at the workshop.

When both are green, print:

```
============================================================
  Ready! Ruby and Bundler are installed.

  IMPORTANT: Close this conversation and start a new one —
  otherwise Claude keeps the old environment and cannot find
  the fresh Ruby.

  Then run: /init-project "description of what you're building"
============================================================
```

If either check fails, print the exact error and which of the three shell files to inspect.
