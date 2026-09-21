# Plangora Elixir Rules

The house rules for Plangora's Elixir, Ash and Phoenix projects, packaged so that
[`usage_rules`](https://hex.pm/packages/usage_rules) can put them in front of every
coding agent (Claude Code, Cursor, GitHub Copilot) working in one of our repositories.

There is no code here. The package ships:

- `usage-rules.md` — the short list of non-negotiables. Always inlined.
- `usage-rules/*.md` — one file per topic, with the reasoning and examples.
- `usage-rules/skills/plangora-review/` — a pre-PR review checklist agents can load.

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

3. Run `mix deps.get && mix usage_rules.sync` and commit the result.

`usage_rules.sync` writes the rules into `AGENTS.md`, which Claude Code (through
`@AGENTS.md` in `CLAUDE.md`), Cursor and GitHub Copilot all read, and copies the skill
into `.agents/skills/`. Because the synced files are committed, teammates and agents
that never run mix still see the same rules.

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

Where a rule can be checked mechanically, add the Credo check to the project's
`.credo.exs` as well (for example `Credo.Check.Readability.SinglePipe` for the
"no single-function pipes" rule) so it fails before review.
