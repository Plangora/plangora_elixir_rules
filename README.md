# Plangora Elixir Rules

The house rules for Plangora's Elixir, Ash and Phoenix projects, packaged so that
[`usage_rules`](https://hex.pm/packages/usage_rules) can put them in front of every
coding agent (Claude Code, Cursor, GitHub Copilot) working in one of our repositories.

The package ships two things:

- **Rules for agents**: `usage-rules.md` (the short list of non-negotiables, always
  inlined), `usage-rules/*.md` (one file per topic, with the reasoning and examples) and
  `usage-rules/skills/plangora-review/` (a pre-PR review checklist agents can load).
- **A Credo plugin** (`PlangoraElixirRules.Credo`) that enforces the mechanical half of
  those rules in `mix credo`, so they fail before review instead of in it.

## Using it in a project

1. Add the dependency (git, dev/test only):

   ```elixir
   {:plangora_elixir_rules,
    git: "git@github.com:Plangora/plangora_elixir_rules.git", tag: "v0.1.0",
    only: [:dev, :test], runtime: false}
   ```

2. List it in the `usage_rules` project config in `mix.exs`:

   ```elixir
   usage_rules: ["usage_rules:all", "plangora_elixir_rules:all"],
   skills: [
     location: ".agents/skills",
     package_skills: [:plangora_elixir_rules],
     ...
   ]
   ```

3. Add the Credo plugin after `AshCredo` in `.credo.exs`:

   ```elixir
   %{configs: [%{name: "default", plugins: [{AshCredo, []}, {PlangoraElixirRules.Credo, []}]}]}
   ```

   and an alias so the DSL-reading checks see a compiled project:

   ```elixir
   lint: ["compile", "credo --strict"]
   ```

4. Run `mix deps.get && mix usage_rules.sync` and commit the result.

`usage_rules.sync` writes the rules into `AGENTS.md`, which Claude Code (through
`@AGENTS.md` in `CLAUDE.md`), Cursor and GitHub Copilot all read, and copies the skill
into `.agents/skills/`. Because the synced files are committed, teammates and agents
that never run mix still see the same rules.

## What Credo enforces

| Rule | Check |
|---|---|
| Pipe only with two or more calls | `Credo.Check.Readability.SinglePipe` |
| `@moduledoc` everywhere | `Credo.Check.Readability.ModuleDoc` |
| No nested `case` | `Credo.Check.Refactor.Nesting` |
| Actor on every Ash call, no `authorize?: false` | `AshCredo.Check.Warning.AuthorizeFalse`, `ActorOnCallOptions` |
| No `accept :*` | `AshCredo.Check.Warning.WildcardAcceptOnAction` |
| Secrets marked `sensitive?` | `AshCredo.Check.Warning.SensitiveAttributeExposed` |
| Policies present and scoped | `AshCredo.Check.Warning.AuthorizerWithoutPolicies`, `OverlyPermissivePolicy` |
| `belongs_to` declares `allow_nil?` | `AshCredo.Check.Readability.BelongsToMissingAllowNil` |
| `timestamps()` on every resource | `AshCredo.Check.Design.MissingTimestamps` |
| Relationships via argument + `manage_relationship` | `PlangoraElixirRules.Check.Ash.ForeignKeyInAccept`, `AttributeWritable`, `StandaloneForeignKeyAttribute` |
| Archival + paper trail on every resource | `PlangoraElixirRules.Check.Ash.MissingArchivalOrPaperTrail` |
| `public? true` on attributes, relationships, calculations, aggregates | `PlangoraElixirRules.Check.Ash.MissingPublic` |
| `expr/1` inline, no `require Ash.Expr` | `PlangoraElixirRules.Check.Ash.RequireAshExpr` |
| Enum labels through gettext | `PlangoraElixirRules.Check.Ash.EnumLabelWithoutGettext` |
| Components, not raw `<button>`/`<a>`/`<select>`/`<input>`/`<textarea>` | `PlangoraElixirRules.Check.Web.RawHtmlElement` |
| `:if`/`:for`, not `<%= if %>`/`<%= for %>` | `PlangoraElixirRules.Check.Web.EexControlFlow` |
| Dates through `Localize` | `PlangoraElixirRules.Check.Web.StrftimeInWeb` |
| Factory functions called bare | `PlangoraElixirRules.Check.Test.FactoryModulePrefix` |
| `async: true` | `PlangoraElixirRules.Check.Test.AsyncFalse` |

Every check documents itself: `mix credo explain PlangoraElixirRules.Check.Ash.MissingPublic`.
The template checks only see `~H` sigils in `.ex` files; `.heex` templates are not
Elixir and Credo does not load them, so those stay a review item. Rules that need
judgement (gettext coverage, permissions as policies, loads with the parent, when a
worker may skip the actor) are not checked mechanically; they live in the usage rules.

Disable or tune a check per project in `.credo.exs`, and per line with
`# credo:disable-for-next-line` plus a comment saying why.

## Adding or changing a rule

1. Pick the topic file in `usage-rules/` (or add a new one; the file name becomes the
   sub-rule name, `plangora_elixir_rules:<file>`).
2. Write the rule as: the rule in one sentence, a BAD/GOOD example, and the reason.
   Keep the reviewer's own wording when the rule came from a review comment; agents
   follow "the owner said X" better than an abstract principle.
3. If it belongs on the short list, add one line to `usage-rules.md` too.
4. Bump the version in `mix.exs`, commit, tag (`git tag v0.x.y && git push --tags`).
5. In each project: update the `tag:` in `mix.exs`, `mix deps.update plangora_elixir_rules`,
   `mix usage_rules.sync`, commit.

Where the rule can be checked mechanically, add a check under
`lib/plangora_elixir_rules/check/` (source-AST, modelled on the existing ones; the
`AshCredo.Orchestration`/`Introspection` helpers iterate resources and DSL sections),
register it in `PlangoraElixirRules.Credo`'s config, and add a test under `test/` using
`Credo.Test.Case`. `mix test` in this repo runs them.
