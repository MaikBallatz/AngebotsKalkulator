---
paths:
  - "db/**"
  - "app/models/**"
---

# You are touching the database

## Generating a model

Always pass `--no-test-framework`:

```bash
bin/rails generate model Interview candidate:string position:string user:references --no-test-framework
```

Without the flag the generator drops a pending spec, and "pending" reads as broken to
anyone who cannot read a backtrace. There is no global switch for this one — the
`config.generators` block only silences the controller-side specs. The model's real
test is the failing request spec you write in the RED step; a placeholder adds nothing.

## Migrations (SQLite)

- Use the `change` method for reversible migrations
- Add indexes for every foreign key and every column you query by
- Add `null: false` constraints at the DB level for required fields
- Always verify with `bin/rails db:migrate` and test rollback with `bin/rails db:rollback`
- SQLite note: no concurrent index creation — just use standard `add_index`

```ruby
class CreatePosts < ActiveRecord::Migration[8.1]  # keep whatever version the generator wrote
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.timestamps
    end
    add_index :posts, :created_at
  end
end
```

## Ownership

Every model belongs to a user, directly or through a parent. When you add one:

1. `belongs_to :user` (or to an already user-owned parent)
2. `has_many` on User with `dependent: :destroy`
3. `user_id` foreign key with NOT NULL + index in the migration
4. Scope every controller query through `current_user`

The scoping examples for *this* project — with its real model names — are in CLAUDE.md, Part 1. This file holds the generic recipe; that file holds the specifics. Neither repeats the other.

**Deliberate exception: a shared, non-user-owned model.** Not every model represents one user's data — a resource genuinely shared across every signed-in person (like `UseCase`, the Werkstatt-Cockpit) has no `user_id` and its controller queries stay unscoped by design. Document this in a comment at the top of the model, same as `app/models/use_case.rb` does, and gate *write* access (and, if the resource isn't meant for everyone, *read* access too) through an explicit predicate — `member?`/`editable_by?`/`visible_to?` — instead of `current_user` scoping. This is the only case where rule 4 above doesn't apply; every other model still follows it.
