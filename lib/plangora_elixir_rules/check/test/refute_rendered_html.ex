defmodule PlangoraElixirRules.Check.Test.RefuteRenderedHtml do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    tags: [:test, :plangora],
    explanations: [
      check: """
      `refute html =~ "text"` against rendered HTML is unsound: entity escaping
      (`&#39;`), SVG path data and attribute values make the substring appear or
      disappear for reasons unrelated to the assertion, and the suite goes
      flaky. Assert on the DOM instead.

          # Bad
          refute html =~ "Delete"
          refute render(view) =~ project.name

          # Good
          refute has_element?(view, "#delete-button")
          refute has_element?(view, "#project-\#{project.id}")
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
          message:
            "`refute ... =~` against rendered HTML; assert on a DOM id with `has_element?/2`.",
          line_no: line,
          trigger: "refute"
        )
      end)
    else
      []
    end
  end

  defp walk({:refute, meta, [{:=~, _, [left, _right]}]} = ast, acc) do
    if rendered_html?(left), do: {ast, [meta[:line] | acc]}, else: {ast, acc}
  end

  defp walk(ast, acc), do: {ast, acc}

  defp rendered_html?({name, _, nil}) when name in [:html, :rendered, :body], do: true

  defp rendered_html?({name, _, args}) when is_atom(name) and is_list(args),
    do: String.starts_with?(Atom.to_string(name), "render")

  defp rendered_html?(_), do: false
end
