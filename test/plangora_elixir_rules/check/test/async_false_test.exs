defmodule PlangoraElixirRules.Check.Test.AsyncFalseTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Test.AsyncFalse

  test "flags async: false in a test module" do
    """
    defmodule MyApp.SyncTest do
      use MyApp.DataCase, async: false
    end
    """
    |> to_source_file("test/my_app/sync_test.exs")
    |> run_check(AsyncFalse)
    |> assert_issue()

    """
    defmodule MyApp.AsyncTest do
      use MyApp.DataCase, async: true
    end
    """
    |> to_source_file("test/my_app/async_test.exs")
    |> run_check(AsyncFalse)
    |> refute_issues()
  end
end
