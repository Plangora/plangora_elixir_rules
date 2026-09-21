defmodule PlangoraElixirRules.Check.Ash.AttributeWritable do
  use Credo.Check,
    base_priority: :high,
    category: :design,
    tags: [:ash, :plangora],
    explanations: [
      check: """
      `attribute_writable? true` on a relationship makes the foreign key column
      writable through `accept`, which is exactly the shortcut the house rule
      forbids.

          # Bad
          belongs_to :role, MyApp.Role, attribute_writable?: true

          # Good
          belongs_to :role, MyApp.Role, allow_nil?: false, public?: true

      and take the id as an argument with `manage_relationship` on the action.
      """
    ]

  alias AshCredo.Orchestration
  alias PlangoraElixirRules.Check.Helpers

  @impl true
  def run(%SourceFile{} = source_file, params) do
    Orchestration.flat_map_resource_section(source_file, params, :relationships, fn sections,
                                                                                    issue_meta ->
      sections
      |> Enum.flat_map(
        &Helpers.entity_calls(&1, [:belongs_to, :has_one, :has_many, :many_to_many])
      )
      |> Enum.filter(&(Helpers.entity_options(&1)[:attribute_writable?] == true))
      |> Enum.map(fn entity ->
        format_issue(issue_meta,
          message:
            "`#{Helpers.entity_name(entity)}` is `attribute_writable?`; drop it and manage " <>
              "the relationship through an argument.",
          line_no: Helpers.line(entity),
          trigger: "attribute_writable?"
        )
      end)
    end)
  end
end
