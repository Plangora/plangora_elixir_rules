# Elixir style

## Pipes

Pipe only when there are two or more calls in the chain. A single call is a plain
call ("no need to pipe this", "inline this, no need to pipe"; and for chains: "let's
use the pipeline style, looks nicer", "you can pipe the `Ash.get/3` into `Ash.Changeset`, too").

```elixir
# BAD
role_id |> Ash.get!(Role)
user = socket.assigns.current_user |> load_actor()

# GOOD
Ash.get!(Role, role_id)
user = load_actor(socket.assigns.current_user)

Role
|> Ash.get!(role_id, actor: actor)
|> Ash.Changeset.for_update(:make_default, %{}, actor: actor)
|> Ash.update()
```

`Credo.Check.Readability.SinglePipe` enforces this; keep it enabled in `.credo.exs`.

## Small things the owner keeps asking for

- Inline a helper that is used once ("if this is only used in 1 place, then inline it").
- Combine two clauses that return the same value: `_ -> :error`.
- No comments that restate the code ("no need to comment this, it's quite clear what it is").
- `@moduledoc` on every module, `@doc` (and `@spec` where the file already uses them)
  on public functions, especially callbacks and helpers others will call.
- TODOs are allowed for known gaps, phrased as what to do later.
- No commented-out code, no compatibility shims, no dead defensive code once the
  thing it guarded is gone.
