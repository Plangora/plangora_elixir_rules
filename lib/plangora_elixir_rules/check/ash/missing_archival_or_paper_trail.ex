defmodule PlangoraElixirRules.Check.Ash.MissingArchivalOrPaperTrail do
  use Credo.Check,
    base_priority: :high,
    category: :design,
    tags: [:ash, :plangora],
    param_defaults: [
      require_archival: true,
      require_paper_trail: true,
      ignored_modules: []
    ],
    explanations: [
      check: """
      Every Postgres-backed resource carries `AshArchival.Resource` and
      `AshPaperTrail.Resource`, join tables included ("we should have
      `ash_archival` and `ash_paper_trail`").

          use Ash.Resource,
            domain: MyApp.Domain,
            data_layer: AshPostgres.DataLayer,
            extensions: [AshPaperTrail.Resource, AshArchival.Resource],
            authorizers: [Ash.Policy.Authorizer]

      Resources whose `postgres` block sets `migrate? false` (database views)
      are skipped, as are modules listed in `ignored_modules`. A resource that
      must not archive (an authentication identity looked up by a library on
      the hot path, say) documents why and goes on that list.
      """,
      params: [
        require_archival: "Require `AshArchival.Resource` (default `true`).",
        require_paper_trail: "Require `AshPaperTrail.Resource` (default `true`).",
        ignored_modules: "Module names (strings) to skip, e.g. `[\"MyApp.Accounts.Token\"]`."
      ]
    ]

  alias AshCredo.Introspection
  alias AshCredo.Introspection.ResourceContext
  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{} = source_file, params) do
    Orchestration.flat_map_resource_context(source_file, params, fn context, issue_meta ->
      if postgres_resource?(context) and not ignored?(context, params) and not view?(context) do
        missing(context, params)
        |> Enum.map(fn extension ->
          format_issue(issue_meta,
            message:
              "Resource does not use `#{extension}`; every resource gets archival and " <>
                "paper trail in the house shape.",
            line_no: context.use_line || 1,
            trigger: "use Ash.Resource"
          )
        end)
      else
        []
      end
    end)
  end

  defp postgres_resource?(context) do
    match?(
      {:__aliases__, _, [:AshPostgres, :DataLayer]},
      Introspection.resource_data_layer(context)
    )
  end

  defp view?(context) do
    context
    |> Introspection.resource_sections(:postgres)
    |> Enum.any?(fn section ->
      section
      |> Helpers.entity_calls(:migrate?)
      |> Enum.any?(&match?({:migrate?, _, [false]}, &1))
    end)
  end

  defp ignored?(%ResourceContext{absolute_segments: nil}, _params), do: false

  defp ignored?(%ResourceContext{absolute_segments: segments}, params) do
    Enum.join(segments, ".") in List.wrap(Params.get(params, :ignored_modules, __MODULE__))
  end

  defp missing(%ResourceContext{use_opts: opts}, params) do
    extensions =
      opts
      |> Keyword.get(:extensions, [])
      |> List.wrap()
      |> Enum.map(fn
        {:__aliases__, _, segments} -> Enum.join(segments, ".")
        other -> inspect(other)
      end)

    required =
      List.flatten([
        if(Params.get(params, :require_paper_trail, __MODULE__),
          do: ["AshPaperTrail.Resource"],
          else: []
        ),
        if(Params.get(params, :require_archival, __MODULE__),
          do: ["AshArchival.Resource"],
          else: []
        )
      ])

    Enum.reject(required, &(&1 in extensions))
  end
end
