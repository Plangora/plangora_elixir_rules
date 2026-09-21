defmodule PlangoraElixirRules.Check.Ash.StandaloneForeignKeyAttribute do
  use Credo.Check,
    base_priority: :normal,
    category: :design,
    tags: [:ash, :plangora],
    explanations: [
      check: """
      A `belongs_to :user` already defines the `user_id` attribute. Declaring
      `attribute :user_id` next to it duplicates the column definition and
      invites writing the key directly.

          # Bad
          attribute :user_id, :uuid, allow_nil?: false
          belongs_to :user, MyApp.User

          # Good
          belongs_to :user, MyApp.User, allow_nil?: false, public?: true
      """
    ]

  alias AshCredo.Introspection
  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{} = source_file, params) do
    Orchestration.flat_map_resource_context(source_file, params, fn context, issue_meta ->
      relationship_names =
        context
        |> Introspection.resource_sections(:relationships)
        |> Enum.flat_map(&Helpers.entity_calls(&1, :belongs_to))
        |> Enum.map(&Helpers.entity_name/1)
        |> MapSet.new()

      context
      |> Introspection.resource_sections(:attributes)
      |> Enum.flat_map(&Helpers.entity_calls(&1, :attribute))
      |> Enum.filter(fn attribute ->
        case Helpers.entity_name(attribute) do
          nil -> false
          name -> foreign_key_of(name) in relationship_names
        end
      end)
      |> Enum.map(fn attribute ->
        name = Helpers.entity_name(attribute)

        format_issue(issue_meta,
          message:
            "`attribute :#{name}` duplicates the `belongs_to :#{foreign_key_of(name)}` " <>
              "relationship; remove it and keep the relationship.",
          line_no: Helpers.line(attribute),
          trigger: ":#{name}"
        )
      end)
    end)
  end

  defp foreign_key_of(name) do
    name
    |> Atom.to_string()
    |> String.replace_suffix("_id", "")
    |> String.to_atom()
  end
end
