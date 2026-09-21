# Ash expressions and checks

## Ash.Query.filter — no import, no expr()

`Ash.Query.filter/2` is a macro that takes expression syntax directly. Do not
`import Ash.Expr` or wrap the filter in `expr()`.

```elixir
# BAD
import Ash.Expr
Resource |> Ash.Query.filter(expr(serial_number == ^serial_number))

# GOOD
Resource |> Ash.Query.filter(serial_number == ^serial_number)
Resource |> Ash.Query.filter(exists(devices, library_id == ^library_id))
```

## Resource DSL — use expr()

Inside a resource (policies, action filters, calculations, changes) use `expr/1`;
`use Ash.Resource` provides it, no import needed.

```elixir
policy action_type(:read) do
  authorize_if expr(exists(members, user_id == ^actor(:id)))
end

read :for_self do
  filter expr(user_id == ^actor(:id))
end
```

`import Ash.Expr` is only for standalone expressions outside those two places, such
as `Ash.Query.build(..., filter: expr(...))`, `fragment(...)` or `expr_sort/2`.

## Checks

Owner: "why not use an expression?", "i think we dont need to do like this, we can
directly use the expression syntax", "`expr/1` should already have been imported, so no
need for `require Ash.Expr`".

Prefer an inline `expr(...)` in the policy. When a check module is needed because the
same expression is reused with a `path:` option, it is a `FilterCheck` that returns
`expr(exists(^path, ...))`:

```elixir
defmodule MyApp.Access.Checks.ProjectMember do
  @moduledoc "Authorizes records whose project (at `path`) lists the actor in `accesses`."
  use Ash.Policy.FilterCheck

  @impl true
  def describe(opts), do: "actor has access to the project at #{inspect(opts[:path])}"

  @impl true
  def filter(nil, _context, _opts), do: false

  def filter(actor, _context, opts) do
    path = Keyword.get(opts, :path, []) ++ [:accesses]
    expr(exists(^path, user_id == ^actor.id))
  end
end
```

No `require Ash.Expr`, no `Ash.Query.Exists.new/2`. A `SimpleCheck` is acceptable only
where a filter cannot express the decision (a forbidden decision that must carry an
error message, a create with no record yet); its moduledoc says why.

Two traps worth knowing: a `FilterCheck` cannot authorize a `create`; and a filter
that traverses an absent relationship evaluates to SQL `NULL`, which excludes the row
in an `authorize_if` and never fires in a `forbid_if`.
