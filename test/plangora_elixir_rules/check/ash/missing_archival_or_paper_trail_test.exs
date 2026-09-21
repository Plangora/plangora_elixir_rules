defmodule PlangoraElixirRules.Check.Ash.MissingArchivalOrPaperTrailTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.MissingArchivalOrPaperTrail

  test "flags each missing extension on a Postgres resource" do
    """
    defmodule MyApp.Tag do
      use Ash.Resource,
        domain: MyApp.Projects,
        data_layer: AshPostgres.DataLayer,
        extensions: [AshArchival.Resource],
        authorizers: [Ash.Policy.Authorizer]
    end
    """
    |> to_source_file("lib/my_app/tag.ex")
    |> run_check(MissingArchivalOrPaperTrail)
    |> assert_issue(fn issue -> assert issue.message =~ "AshPaperTrail.Resource" end)
  end

  test "skips views, embedded resources, ignored modules and complete resources" do
    view = """
    defmodule MyApp.ProjectAccess do
      use Ash.Resource, domain: MyApp.Projects, data_layer: AshPostgres.DataLayer

      postgres do
        table "project_accesses"
        migrate? false
      end
    end
    """

    embedded = """
    defmodule MyApp.Address do
      use Ash.Resource, data_layer: :embedded
    end
    """

    complete = """
    defmodule MyApp.Card do
      use Ash.Resource,
        domain: MyApp.Projects,
        data_layer: AshPostgres.DataLayer,
        extensions: [AshPaperTrail.Resource, AshArchival.Resource]
    end
    """

    ignored = """
    defmodule MyApp.Accounts.Token do
      use Ash.Resource, domain: MyApp.Accounts, data_layer: AshPostgres.DataLayer
    end
    """

    for source <- [view, embedded, complete] do
      source
      |> to_source_file("lib/my_app/x.ex")
      |> run_check(MissingArchivalOrPaperTrail)
      |> refute_issues()
    end

    ignored
    |> to_source_file("lib/my_app/accounts/token.ex")
    |> run_check(MissingArchivalOrPaperTrail, ignored_modules: ["MyApp.Accounts.Token"])
    |> refute_issues()
  end
end
