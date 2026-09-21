defmodule PlangoraElixirRules.Check.Ash.MissingPublicTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.MissingPublic

  test "flags private entities and respects ignored names and block options" do
    """
    defmodule MyApp.User do
      use Ash.Resource, domain: MyApp.Accounts, data_layer: AshPostgres.DataLayer

      attributes do
        uuid_primary_key :id
        attribute :email, :string, allow_nil?: false, public?: true
        attribute :nickname, :string
        attribute :hashed_password, :string, sensitive?: true
        timestamps()
      end

      relationships do
        belongs_to :role, MyApp.Role do
          allow_nil? true
          public? true
        end

        has_many :assignments, MyApp.Assignment
      end

      calculations do
        calculate :display_name, :string, expr(first_name <> " " <> last_name)
      end

      aggregates do
        count :assignment_count, :assignments, public?: true
      end
    end
    """
    |> to_source_file("lib/my_app/user.ex")
    |> run_check(MissingPublic)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.trigger) |> Enum.sort() ==
               [":assignments", ":display_name", ":nickname"]
    end)
  end
end
