defmodule PlangoraElixirRules.Check.Web.StrftimeInWebTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Web.StrftimeInWeb

  @source """
  defmodule Formatting do
    def when_(dt), do: Calendar.strftime(dt, "%d %b")
  end
  """

  test "flags Calendar.strftime in the web layer only" do
    @source
    |> to_source_file("lib/my_app_web/live/x.ex")
    |> run_check(StrftimeInWeb)
    |> assert_issue()

    @source
    |> to_source_file("lib/my_app/reports.ex")
    |> run_check(StrftimeInWeb)
    |> refute_issues()
  end
end
