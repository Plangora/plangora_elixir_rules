# Plangora house rules

These are the rules the repository owner enforces in code review. Follow them without
being asked. The topic files under `usage-rules/` carry the reasoning and examples.

## Ash resources
- Every resource gets `AshArchival.Resource` and `AshPaperTrail.Resource`, in the house
  shape (see `ash-resources`). Join tables too.
- Relationships are changed through `argument` + `change manage_relationship(...)`.
  Never `accept` a `*_id`, never `attribute_writable? true`, never a standalone
  `attribute :foo_id` next to a `belongs_to :foo`.
- Attributes, relationships, calculations and aggregates are `public? true` unless
  they hold a secret.
- Use `defaults [...]` and `default_accept` for plain CRUD; state transitions `accept []`.
- Permission rules are policies, not validations. Prefer `expr(...)` checks over check
  modules; no `require Ash.Expr` in a check.
- Enums are `Ash.Type.Enum` with `gettext` labels. Every user-facing message is `gettext`.
- Load related data with the parent (`load:`), sort in the query, aggregate in the
  resource, search through a `read :search` action with `contains/2`, find-or-create
  through `create` with `upsert? true`.

## Actors
- Every Ash call that can take an actor takes one. `authorize?: false` is allowed only
  inside a resource's own hooks within an already-authorized action, or in a worker
  with no human actor, and always with a one-line comment saying why.
- The web layer checks permissions with `Ash.can?/2`; it never re-implements a policy.

## Migrations
- `mix ash.codegen --name <snake_case>` generates migrations and snapshots. Never call
  `mix ash_postgres.generate_migrations`, never hand-edit or delete snapshots, never
  rename a deployed migration. Data SQL lives inside the migration file. Migrations are
  not unit-tested.

## Web
- `<.button>`, `<.link>`, `<.input>` (and the project's `Buttons` components) instead
  of raw `<button>`, `<a>`, `<select>`, `<input>`, `<textarea>`.
- `:if` / `:for` attributes, not `<%= if %>` / `<%= for %>` blocks.
- `AshPhoenix.Form` with `field={@form[:x]}`; `prepare_params` for derived fields.
- `Localize` for every date, time, number and currency; `display_name` for people.
- Admin-only screens live under `/admin`.

## Style
- Pipe only when there are two or more calls in the chain; a single call is written
  as a plain call.
- Inline a helper used once; one `assign/2` with a keyword list; pattern-match
  instead of `if`; no nested `case`.
- Every module has a `@moduledoc`; public functions have `@doc`.

## Tests
- Records come from the factory: `generate(user())` / `user() |> generate()`; factory
  functions are imported, never called as `Plangora.Factory.user()`.
- `async: true` everywhere; use Mox instead of global config.
- Assert with `Ash.count!/2`, `Ash.get!/2`, `has_element?/2`; `assert`/`refute html =~`
  on rendered HTML is fine too.
- Pass the actor in tests too; `authorize?: false` hides what the test should prove.

## Enforcement
- `mix credo --strict` runs the mechanical half of these rules through the
  `PlangoraElixirRules.Credo` plugin; a check you disable for a line needs a comment
  saying why. Run it (through the project's `lint` alias) before opening a pull request.

## Repository
- No plan, report or design files committed (`docs/` and `.superpowers/` are ignored).
- No commented-out code, no shims, no dead defensive code.
