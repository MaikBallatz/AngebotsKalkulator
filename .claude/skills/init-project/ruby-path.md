# Reference — why the Ruby path is fragile, and what fixes it

Background for Step 6 of `/init-project`. Read this only when the binstub
shebang step misbehaves, or when porting the harness to a new environment.
The commands themselves live in the skill; this file explains why they look
the way they do.

## The problem, stated precisely

Claude's tool shell is a **non-interactive zsh without login**. That means:

- `~/.zshenv` **is read** — zsh reads it in every mode, always.
- `~/.zprofile` and `~/.zshrc` are **skipped** — login and interactive config
  never run.

An earlier version of this file claimed all shell profiles were ignored.
That is wrong for zsh, and the difference matters: it is exactly why
`/init-dependencies` writes the rbenv shims PATH into `~/.zshenv` — that one
line is what makes `ruby` resolve correctly inside the tool shell. What the
tool shell *cannot* get is anything that only lives in `.zprofile`/`.zshrc`.

When the shims are not on PATH, macOS serves its built-in Ruby 2.6 and
everything breaks:

```
Your Ruby version is 2.6.10, but your Gemfile specified ~> 3.4
(Bundler::RubyVersionMismatch)
```

A second trap sits in login shells: macOS runs `/etc/zprofile`
(`path_helper`) *after* `~/.zshenv`, and it pushes `/usr/bin` back in front
of the shims. That is why `/init-dependencies` re-exports the shims path at
the **end of `~/.zprofile`** — without it, every new Terminal window shows
the system Ruby again even though the installation succeeded.

## The two lines of defence

**First: the shims PATH in `~/.zshenv`** (set by `/init-dependencies`).
With it, `#!/usr/bin/env ruby` resolves to rbenv's shim and everything
works, in the tool shell and in terminals alike.

**Second: pinned shebangs** (set by `/init-project` Step 6). Every file in
`bin/` whose shebang is `#!/usr/bin/env ruby` gets rewritten to the absolute
path of rbenv's ruby. The kernel reads that line and invokes the interpreter
directly; PATH is never consulted. This holds even when the `.zshenv` entry
is missing or was defeated — a fresh machine where someone skipped
`/init-dependencies`, a different shell, a broken profile.

Two constraints shape the exact command:

**Guard on rbenv actually existing.** On a machine managed by asdf, mise or
a system Ruby, `~/.rbenv/versions/<v>/bin/ruby` does not exist. Rewriting
shebangs to that path turns every working binstub into a broken one. Without
rbenv, leaving `#!/usr/bin/env ruby` in place is correct — PATH resolves
fine there.

**Use `perl -pi -e`, not `sed -i ''`.** The empty-argument form of `-i` is
BSD-only. GNU sed (Ubuntu, and therefore WSL) reads the empty string as the
script and the expression as a filename, and fails. `perl` ships with macOS
and every Ubuntu install.

## Manual repair

If binstubs already exist and were generated before Step 6 ran:

```bash
RUBY_V="$(cat .ruby-version)"
RUBY_BIN="$HOME/.rbenv/versions/${RUBY_V}/bin/ruby"
[ -x "$RUBY_BIN" ] || echo "no rbenv here — leave the shebangs alone"
for f in bin/*; do
  [ -f "$f" ] && head -1 "$f" | grep -q '^#!/usr/bin/env ruby$' && \
    perl -pi -e "s|^#!/usr/bin/env ruby$|#!${RUBY_BIN}|" "$f"
done
head -1 bin/rails
```

## If you are stuck before binstubs exist

Prefix the command with an explicit PATH export:

```bash
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH" && ruby -v
# should print the version from .ruby-version
```

## Note on the server side

Do not carry this fix into a deployment. A rewritten shebang holds a macOS
absolute path, `bin/` is committed, and that path does not exist in a Linux
container. Keep the two layers separate: the local fix stays local, and the
server should never execute a repo binstub.
