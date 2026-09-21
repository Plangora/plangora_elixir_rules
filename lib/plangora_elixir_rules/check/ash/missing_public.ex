defmodule PlangoraElixirRules.Check.Ash.MissingPublic do
  use Credo.Check,
    base_priority: :normal,
    category: :design,
    tags: [:ash, :plangora],
    param_defaults: [
      ignored_names: [:hashed_password, :token, :access_token, :refresh_token],
      excluded_paths: AshCredo.PathFilter.default_excluded_paths()
    ],
    explanations: [
      check: """
      Attributes, relationships, calculations and aggregates are `public? true`
      unless they hold a secret ("make public", "let's add `public? true`").

          attribute :title, :string, allow_nil?: false, public?: true
          belongs_to :project, MyApp.Project, allow_nil?: false, public?: true
          calculate :in_use_count, :integer, expr(a + b), public?: true

      Secrets stay private; list their names in `ignored_names`.
      """,
      params: [
        ignored_names: "Entity names that are allowed to stay private.",
        excluded_paths: "Paths or regexes to skip (defaults to test directories)."
      ]
    ]

  alias AshCredo.Introspection
  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @entities %{
    attributes: [:attribute],
    relationships: [:belongs_to, :has_one, :has_many, :many_to_many],
    calculations: [:calculate],
    aggregates: [:count, :sum, :first, :list, :max, :min, :avg, :exists, :custom]
  }

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if AshCredo.PathFilter.excluded?(filename, Params.get(params, :excluded_paths, __MODULE__)) do
      []
    else
      Orchestration.flat_map_resource_context(source_file, params, fn context, issue_meta ->
        Enum.flat_map(@entities, fn {section, names} ->
          context
          |> Introspection.resource_sections(section)
          |> Enum.flat_map(&Helpers.entity_calls(&1, names))
          |> Enum.reject(&(public?(&1) or ignored?(&1, params)))
          |> Enum.map(fn entity ->
            {kind, _, _} = entity

            format_issue(issue_meta,
              message: "`#{kind} :#{Helpers.entity_name(entity)}` is not `public? true`.",
              line_no: Helpers.line(entity),
              trigger: ":#{Helpers.entity_name(entity)}"
            )
          end)
        end)
      end)
    end
  end

  defp public?(entity), do: Helpers.entity_options(entity)[:public?] == true

  defp ignored?(entity, params),
    do: Helpers.entity_name(entity) in List.wrap(Params.get(params, :ignored_names, __MODULE__))
end
