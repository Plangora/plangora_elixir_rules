defmodule PlangoraElixirRules.Check.Ash.StandaloneForeignKeyAttributeTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.StandaloneForeignKeyAttribute

  test "flags an attribute that duplicates a belongs_to" do
    """
    defmodule MyApp.Spotlight do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      attributes do
        uuid_primary_key :id
        attribute :message_id, :uuid
        attribute :record_id, :uuid, allow_nil?: false, public?: true
      end

      relationships do
        belongs_to :message, MyApp.Message
      end
    end
    """
    |> to_source_file("lib/my_app/spotlight.ex")
    |> run_check(StandaloneForeignKeyAttribute)
    |> assert_issue(fn issue -> assert issue.trigger == ":message_id" end)
  end
end
