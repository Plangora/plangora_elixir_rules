defmodule PlangoraElixirRules.Check.Web.EexControlFlow do
  use Credo.Check,
    base_priority: :normal,
    category: :readability,
    tags: [:phoenix, :plangora],
    explanations: [
      check: """
      Conditionals and loops in templates are `:if` and `:for` attributes, not
      EEx blocks ("use the `:if` on the `<p>` tag", "use `:for`").

          <%!-- Bad --%>
          <%= if @board do %><p>...</p><% end %>
          <%= for item <- @items do %><li>...</li><% end %>

          <%!-- Good --%>
          <p :if={@board}>...</p>
          <li :for={item <- @items}>...</li>
      """
    ]

  alias PlangoraElixirRules.Check.Helpers

  @block ~r/<%=\s*(if|unless|for|case|cond)\b/

  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Helpers.heex_sigils()
    |> Enum.flat_map(fn {line, text} -> Helpers.scan_lines(text, line, @block) end)
    |> Enum.map(fn {line, match} ->
      [_, keyword] = Regex.run(@block, match)

      format_issue(issue_meta,
        message:
          "`<%= #{keyword} %>` block in a template; use the `:if`/`:for` attribute instead.",
        line_no: line,
        trigger: match
      )
    end)
  end
end
