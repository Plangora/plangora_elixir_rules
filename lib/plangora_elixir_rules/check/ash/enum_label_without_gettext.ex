defmodule PlangoraElixirRules.Check.Ash.EnumLabelWithoutGettext do
  use Credo.Check,
    base_priority: :normal,
    category: :readability,
    tags: [:ash, :plangora, :i18n],
    explanations: [
      check: """
      Enum labels are user-facing text, so they go through gettext ("let's use
      `Ash.Type.Enum` with a `gettext` label", "these should be in gettext").

          use Gettext, backend: MyAppWeb.Gettext

          use Ash.Type.Enum,
            values: [
              staff: [label: gettext("Staff")],
              client: [label: gettext("Client")]
            ]

          def label(nil), do: nil

          def label(value) do
            with label when is_binary(label) <- super(value) do
              Gettext.gettext(MyAppWeb.Gettext, label)
            end
          end
      """
    ]

  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&walk/2, [])
    |> Enum.reverse()
    |> Enum.map(fn {line, label} ->
      format_issue(issue_meta,
        message: "Enum label #{inspect(label)} is a plain string; wrap it in `gettext/1`.",
        line_no: line,
        trigger: inspect(label)
      )
    end)
  end

  defp walk({:use, meta, [{:__aliases__, _, [:Ash, :Type, :Enum]}, opts]} = ast, acc)
       when is_list(opts) do
    labels =
      opts
      |> Keyword.get(:values, [])
      |> List.wrap()
      |> Enum.flat_map(fn
        {_value, entity_opts} when is_list(entity_opts) ->
          case Keyword.get(entity_opts, :label) do
            label when is_binary(label) -> [{meta[:line], label}]
            _ -> []
          end

        _ ->
          []
      end)

    {ast, Enum.reverse(labels) ++ acc}
  end

  defp walk(ast, acc), do: {ast, acc}
end
