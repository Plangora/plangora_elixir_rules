defmodule PlangoraElixirRules.Check.Test.FactoryModulePrefix do
  use Credo.Check,
    base_priority: :low,
    category: :readability,
    tags: [:test, :plangora],
    explanations: [
      check: """
      Factory functions are imported into every test case, so they are called
      bare ("remove all `Plangora.Factory` in the test files as they are already imported").

          # Bad
          user = Plangora.Factory.user(admin: true) |> generate()

          # Good
          user = generate(user(admin: true))
      """
    ]

  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if Helpers.test_file?(filename) and not String.contains?(filename, "/support/") do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&walk/2, [])
      |> Enum.reverse()
      |> Enum.map(fn {line, call} ->
        format_issue(issue_meta,
          message: "`#{call}` is called through the factory module; the factory is imported.",
          line_no: line,
          trigger: call
        )
      end)
    else
      []
    end
  end

  defp walk({{:., _, [{:__aliases__, _, segments}, fun]}, meta, _} = ast, acc) do
    if List.last(segments) == :Factory do
      {ast, [{meta[:line], "#{Enum.join(segments, ".")}.#{fun}"} | acc]}
    else
      {ast, acc}
    end
  end

  defp walk(ast, acc), do: {ast, acc}
end
