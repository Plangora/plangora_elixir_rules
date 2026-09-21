defmodule PlangoraElixirRules.Check.Test.AsyncFalse do
  use Credo.Check,
    base_priority: :normal,
    category: :design,
    tags: [:test, :plangora],
    explanations: [
      check: """
      Every test module runs async ("why `async: false`?", "can we replace this
      with Mox instead? if so, then we can change this test to be `async: true`").
      Replace global config and named processes with Mox or per-test injection.
      A module that genuinely cannot be async says why in a comment and
      disables this check for that line.
      """
    ]

  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if Helpers.test_file?(filename) do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&walk/2, [])
      |> Enum.reverse()
      |> Enum.map(fn line ->
        format_issue(issue_meta,
          message: "Test module is `async: false`; make it async or document why it cannot be.",
          line_no: line,
          trigger: "async: false"
        )
      end)
    else
      []
    end
  end

  defp walk({:use, meta, [_case, opts]} = ast, acc) when is_list(opts) do
    if Keyword.get(opts, :async) == false, do: {ast, [meta[:line] | acc]}, else: {ast, acc}
  end

  defp walk(ast, acc), do: {ast, acc}
end
