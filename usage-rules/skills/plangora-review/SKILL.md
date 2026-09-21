---
name: plangora-review
description: Pre-PR checklist for Plangora Elixir/Ash/Phoenix projects. Load it before opening or reviewing a pull request, or when asked to apply the house rules to a branch.
---

# Plangora review checklist

Work through every owned file in `lib/` and `test/`. The sweep below finds the
mechanical cases; then read each file for the rest. The rules and their reasons are in
the `plangora_elixir_rules` usage rules in `AGENTS.md`.

## Mechanical sweep

```bash
# resources
grep -rnE 'attribute_writable\?|^\s*attribute :\w+_id, :uuid|accept \[.*_id' lib/
grep -rLE 'AshArchival.Resource' $(grep -rl 'use Ash.Resource' lib/)
grep -rLE 'AshPaperTrail.Resource' $(grep -rl 'use Ash.Resource' lib/)
grep -rnE 'require Ash\.Expr|Ash\.Query\.Exists\.new' lib/
grep -rnE 'authorize\?: false' lib/ test/
grep -rnE 'use Ash\.Type\.Enum' -l lib/ | xargs grep -L gettext
# web
grep -rnE '<(button|a |select|input |textarea)' lib/*_web/ | grep -v 'type="hidden"\|live_file_input'
grep -rnE '<%= (if|for|case) ' lib/*_web/
grep -rnE 'String\.to_(existing_)?atom|Calendar\.strftime|Enum\.sort' lib/*_web/
# tests
grep -rnE 'async: false|Plangora\.Factory\.|refute .*=~' test/
grep -rnE 'Ash\.(create|Seed\.seed)!?\(' test/
# migrations
mix ash.codegen --check
```

## Read for

1. Every resource: archival + paper trail in the house shape; identities and upserts
   aware of `archived_at`; `public? true`; `defaults`/`default_accept`; enums with
   gettext labels; policies instead of validations for permissions.
2. Every action that sets a relationship: `argument` + `manage_relationship`.
3. Every Ash call: an actor. Every remaining `authorize?: false`: a one-line reason.
4. Every LiveView: components, `:if`/`:for`, gettext, Localize, `AshPhoenix.Form`
   with `field=`, `Ash.can?` for gating, no nested `case`, single `assign`.
5. Every test: factory + `generate/1`, `async: true`, sound assertions, actor passed.
6. Style: no single-call pipes, one-use helpers inlined, `@moduledoc` everywhere.
7. Repository: no plan/report files, no commented-out code, no shims.

## Before opening the PR

- `mix format`, `mix compile --warnings-as-errors`, `mix credo`, full `mix test` on a
  rebuilt test database, `mix ash.codegen --check`.
- Migrations generated with `mix ash.codegen --name ...`, reviewed for duplicates.
- Commit messages say which rule and why.
