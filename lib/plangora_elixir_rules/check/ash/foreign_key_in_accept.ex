defmodule PlangoraElixirRules.Check.Ash.ForeignKeyInAccept do
  use Credo.Check,
    base_priority: :high,
    category: :design,
    tags: [:ash, :plangora],
    param_defaults: [excluded_paths: AshCredo.PathFilter.default_excluded_paths()],
    explanations: [
      check: """
      Relationships are changed through an argument and `manage_relationship`,
      never by accepting the foreign key as an attribute.

          # Bad
          create :create do
            accept [:project_id, :title]
          end

          # Good
          create :create do
            accept [:title]
            argument :project_id, :uuid, allow_nil?: false
            change manage_relationship(:project_id, :project, type: :append_and_remove)
          end

      The params map callers pass is unchanged. The one accepted exception is
      a foreign key that is part of an upsert identity's conflict target; mark
      that line with `# credo:disable-for-next-line` and say why.
      """,
      params: [excluded_paths: "Paths or regexes to skip (defaults to test directories)."]
    ]

  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if AshCredo.PathFilter.excluded?(filename, Params.get(params, :excluded_paths, __MODULE__)) do
      []
    else
      Orchestration.flat_map_resource_section(source_file, params, :actions, fn sections,
                                                                                issue_meta ->
        Enum.flat_map(sections, &issues_in_section(&1, issue_meta))
      end)
    end
  end

  defp issues_in_section(section, issue_meta) do
    accepts =
      section
      |> Helpers.entity_calls([:accept, :default_accept])
      |> Enum.flat_map(fn {_name, meta, [list]} -> foreign_keys(list, meta) end)

    defaults =
      section
      |> Helpers.entity_calls(:defaults)
      |> Enum.flat_map(fn {:defaults, meta, [list]} ->
        list
        |> List.wrap()
        |> Enum.flat_map(fn
          {_action, accepted} when is_list(accepted) -> foreign_keys(accepted, meta)
          _ -> []
        end)
      end)

    Enum.map(accepts ++ defaults, fn {key, line} ->
      format_issue(issue_meta,
        message:
          "`#{key}` is accepted as an attribute; take it as an argument and use " <>
            "`manage_relationship` (house rule: relationships via arguments).",
        line_no: line,
        trigger: ":#{key}"
      )
    end)
  end

  defp foreign_keys(list, meta) when is_list(list) do
    line = Keyword.get(meta, :line, 1)

    list
    |> Enum.filter(&(is_atom(&1) and String.ends_with?(Atom.to_string(&1), "_id")))
    |> Enum.map(&{&1, line})
  end

  defp foreign_keys(_, _), do: []
end
