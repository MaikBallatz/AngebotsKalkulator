---
paths:
  - "app/views/**"
  - "app/helpers/**"
  - "app/javascript/**"
  - "app/assets/tailwind/**"
---

# You are touching the app's surface

Before you write markup or styles, read **`design-system.md`** in the project root. It holds the token roles, the component catalogue and the layout conventions. Do not reconstruct them from memory or from surrounding files.

Two rules apply to every line you write here:

1. **No raw colors, radii or fonts.** No `bg-blue-600`, no `bg-[#E2001A]`, no inline `style=`. Use the design tokens (`bg-brand-600`, `text-ink`, `rounded-card`, …). If the value you need doesn't exist as a token, it belongs in the `@theme` block of `app/assets/tailwind/application.css` first — then you use it.

2. **No improvised components.** If the component table in `design-system.md` has an entry for what you're building, copy its class list verbatim. If it doesn't, add the entry to that table first, then use it. A one-off style in a single view is how a design system erodes in an afternoon.

Changing the app's whole look is never a views job — that is `/design-system`, and it touches exactly one file.

---

## Frontend JavaScript: server-first

Start at the top, only escalate when the level above genuinely can't do it:

1. **Plain HTML + Turbo Drive** — default for ~90% of features, no JS needed
2. **Turbo Frames** — update part of a page without full navigation
3. **Turbo Streams** — update multiple parts of a page from a server response
4. **Stimulus controller** — purely client-side behavior: keyboard nav, drag-drop, real-time input feedback

**Stimulus rules:**
- One controller = one behavior
- ~100 lines max — if longer, it probably does too much
- No domain logic in controllers — business rules stay server-side
- Controllers never call each other — coordinate via DOM events or Turbo
- Features must work without JavaScript (forms still submit, links still navigate)

**Import maps only** — no webpack, esbuild, or Node.js build step.
