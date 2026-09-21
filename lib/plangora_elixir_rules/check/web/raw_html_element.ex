defmodule PlangoraElixirRules.Check.Web.RawHtmlElement do
  use Credo.Check,
    base_priority: :normal,
    category: :readability,
    tags: [:phoenix, :plangora],
    param_defaults: [excluded_paths: [~r"/components/", ~r"/test/", "test"]],
    explanations: [
      check: """
      Templates use the project's components, not raw form and link elements
      ("we should replace all `<button>` with `<.button>` as we have a working
      button implementation already", "replace select with the `<.input>` component").

          # Bad
          <button phx-click="save">Save</button>
          <a href={~p"/x"}>Go</a>
          <select name="kind">...</select>

          # Good
          <.button phx-click="save"><:text>Save</:text></.button>
          <.link navigate={~p"/x"}>Go</.link>
          <.input field={@form[:kind]} type="select" options={@kinds} />

      Hidden inputs and `live_file_input` are fine. Component modules themselves
      are excluded, since that is where the raw elements belong.
      """,
      params: [
        excluded_paths: "Paths or regexes to skip (component modules and tests by default)."
      ]
    ]

  alias PlangoraElixirRules.Check.Helpers

  @element ~r/<(button|a|select|textarea|input)(?=[\s>\/])[^>]*/

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if AshCredo.PathFilter.excluded?(filename, Params.get(params, :excluded_paths, __MODULE__)) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Helpers.heex_sigils()
      |> Enum.flat_map(fn {line, text} -> Helpers.scan_lines(text, line, @element) end)
      |> Enum.reject(fn {_line, tag} -> hidden_input?(tag) end)
      |> Enum.map(fn {line, tag} ->
        [_, name] = Regex.run(~r/^<(\w+)/, tag)

        format_issue(issue_meta,
          message:
            "Raw `<#{name}>` in a template; use the `<.#{component_for(name)}>` component.",
          line_no: line,
          trigger: "<#{name}"
        )
      end)
    end
  end

  defp hidden_input?(tag),
    do: String.starts_with?(tag, "<input") and tag =~ ~r/type=["']hidden["']/

  defp component_for("a"), do: "link"
  defp component_for("button"), do: "button"
  defp component_for(_), do: "input"
end
