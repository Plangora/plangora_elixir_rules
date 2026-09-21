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

      Only the foreign keys of relationships declared on the resource are
      flagged, so a plain `github_id` or `storage_id` attribute is not. The
      params map callers pass is unchanged. The one accepted exception is a
      foreign key that is part of an upsert identity's conflict target; mark
      that line with `# credo:disable-for-next-line` and say why.
      """,
      params: [excluded_paths: "Paths or regexes to skip (defaults to test directories)."]
    ]

  alias AshCredo.Introspection
  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if AshCredo.PathFilter.excluded?(filename, Params.get(params, :excluded_paths, __MODULE__)) do
      []
    else
      Orchestration.flat_map_resource_context(source_file, params, fn context, issue_meta ->
        relationship_keys = relationship_keys(context)

        context
        |> Introspection.resource_sections(:actions)
        |> Enum.flat_map(&issues_in_section(&1, relationship_keys, issue_meta))
      end)
    end
  end

  # Only the foreign keys of relationships declared on this resource: a
  # `github_id` or `storage_id` is an attribute, not a relationship.
  defp relationship_keys(context) do
    context
    |> Introspection.resource_sections(:relationships)
    |> Enum.flat_map(&Helpers.entity_calls(&1, [:belongs_to, :has_one, :has_many, :many_to_many]))
    |> Enum.map(&Helpers.entity_name/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&String.to_atom("#{&1}_id"))
    |> MapSet.new()
  end

  defp issues_in_section(section, relationship_keys, issue_meta) do
    accepts =
      section
      |> Helpers.entity_calls([:accept, :default_accept])
      |> Enum.flat_map(fn {_name, meta, [list]} ->
        foreign_keys(list, meta, relationship_keys)
      end)

    defaults =
      section
      |> Helpers.entity_calls(:defaults)
      |> Enum.flat_map(fn {:defaults, meta, [list]} ->
        list
        |> List.wrap()
        |> Enum.flat_map(fn
          {_action, accepted} when is_list(accepted) ->
            foreign_keys(accepted, meta, relationship_keys)

          _ ->
            []
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

  defp foreign_keys(list, meta, relationship_keys) when is_list(list) do
    line = Keyword.get(meta, :line, 1)

    list
    |> Enum.filter(&(is_atom(&1) and MapSet.member?(relationship_keys, &1)))
    |> Enum.map(&{&1, line})
  end

  defp foreign_keys(_, _, _), do: []
end
