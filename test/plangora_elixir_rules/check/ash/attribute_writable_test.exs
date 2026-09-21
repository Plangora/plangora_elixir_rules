defmodule PlangoraElixirRules.Check.Ash.AttributeWritableTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.AttributeWritable

  test "flags attribute_writable? in keyword and block form" do
    """
    defmodule MyApp.Membership do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      relationships do
        belongs_to :project, MyApp.Project, allow_nil?: false, attribute_writable?: true

        belongs_to :role, MyApp.Role do
          attribute_writable? true
        end

        belongs_to :contact, MyApp.Contact, allow_nil?: false, public?: true
      end
    end
    """
    |> to_source_file("lib/my_app/membership.ex")
    |> run_check(AttributeWritable)
    |> assert_issues(2)
  end
end
