defmodule PlangoraElixirRules.Check.Web.StrftimeInWeb do
  use Credo.Check,
    base_priority: :normal,
    category: :readability,
    tags: [:phoenix, :plangora, :i18n],
    explanations: [
      check: """
      Dates and times shown to people go through `Localize`, which formats
      for the viewer's locale ("this should be using `Localize.DateTime.to_string/2`").

          # Bad
          Calendar.strftime(event.starts_at, "%d %b %Y")

          # Good
          Localize.DateTime.to_string!(event.starts_at, format: :medium)

      Only the web layer (`lib/*_web/`) is checked.
      """
    ]

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if PlangoraElixirRules.Check.Helpers.web_file?(filename) do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&walk/2, [])
      |> Enum.reverse()
      |> Enum.map(fn line ->
        format_issue(issue_meta,
          message: "`Calendar.strftime` in the web layer; format with `Localize`.",
          line_no: line,
          trigger: "Calendar.strftime"
        )
      end)
    else
      []
    end
  end

  defp walk({{:., _, [{:__aliases__, _, [:Calendar]}, :strftime]}, meta, _} = ast, acc),
    do: {ast, [meta[:line] | acc]}

  defp walk(ast, acc), do: {ast, acc}
end
