defmodule PlangoraElixirRules.Check.Test.RefuteRenderedHtmlTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Test.RefuteRenderedHtml

  test "flags refute =~ against html variables and render calls only" do
    """
    defmodule MyAppWeb.CardLiveTest do
      use MyAppWeb.ConnCase, async: true

      test "x", %{conn: conn} do
        {:ok, view, html} = live(conn, "/cards")
        refute html =~ "Delete"
        refute render(view) =~ "Delete"
        refute render_click(view, "x") =~ "Delete"
        refute has_element?(view, "#delete")
        refute error_message =~ "boom"
      end
    end
    """
    |> to_source_file("test/my_app_web/live/card_live_test.exs")
    |> run_check(RefuteRenderedHtml)
    |> assert_issues(3)
  end
end
