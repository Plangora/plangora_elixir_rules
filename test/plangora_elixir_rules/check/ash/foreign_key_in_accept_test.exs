defmodule PlangoraElixirRules.Check.Ash.ForeignKeyInAcceptTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.ForeignKeyInAccept

  test "flags a foreign key in accept, default_accept and defaults" do
    """
    defmodule MyApp.Card do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      actions do
        default_accept [:title, :project_id]
        defaults [:read, create: [:column_id]]

        update :move do
          accept [:position, :column_id]
        end
      end
    end
    """
    |> to_source_file("lib/my_app/card.ex")
    |> run_check(ForeignKeyInAccept)
    |> assert_issues(3)
  end

  test "accepts arguments with manage_relationship, and skips tests" do
    source = """
    defmodule MyApp.Card do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      actions do
        create :create do
          accept [:title]
          argument :project_id, :uuid, allow_nil?: false
          change manage_relationship(:project_id, :project, type: :append_and_remove)
        end
      end
    end
    """

    source
    |> to_source_file("lib/my_app/card.ex")
    |> run_check(ForeignKeyInAccept)
    |> refute_issues()

    """
    defmodule MyApp.Fixture do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      actions do
        create :create do
          accept [:project_id]
        end
      end
    end
    """
    |> to_source_file("test/support/fixture.ex")
    |> run_check(ForeignKeyInAccept)
    |> refute_issues()
  end
end
