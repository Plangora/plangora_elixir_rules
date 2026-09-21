defmodule PlangoraElixirRules.Check.Ash.RequireAshExpr do
  use Credo.Check,
    base_priority: :normal,
    category: :refactor,
    tags: [:ash, :plangora],
    explanations: [
      check: """
      `expr/1` is already available inside resources and policy checks, and
      `Ash.Query.filter/2` takes expression syntax directly. `require Ash.Expr`
      and `Ash.Query.Exists.new/2` are signs of building an expression by hand
      ("`expr/1` should already have been imported, so no need for `require Ash.Expr`").

          # Bad
          require Ash.Expr
          Ash.Query.Exists.new(path, Ash.Expr.expr(user_id == ^actor.id))

          # Good
          expr(exists(^path, user_id == ^actor.id))
      """
    ]

  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&walk/2, [])
    |> Enum.reverse()
    |> Enum.map(fn {line, trigger} ->
      format_issue(issue_meta,
        message: "`#{trigger}` builds an expression by hand; use `expr/1` inline.",
        line_no: line,
        trigger: trigger
      )
    end)
  end

  defp walk({:require, meta, [{:__aliases__, _, [:Ash, :Expr]}]} = ast, acc),
    do: {ast, [{meta[:line], "require Ash.Expr"} | acc]}

  defp walk({{:., _, [{:__aliases__, _, [:Ash, :Query, :Exists]}, :new]}, meta, _} = ast, acc),
    do: {ast, [{meta[:line], "Ash.Query.Exists.new"} | acc]}

  defp walk(ast, acc), do: {ast, acc}
end
