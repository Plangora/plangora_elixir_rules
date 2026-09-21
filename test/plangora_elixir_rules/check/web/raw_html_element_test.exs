defmodule PlangoraElixirRules.Check.Web.RawHtmlElementTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Web.RawHtmlElement

  @template ~S'''
  defmodule MyAppWeb.CardLive do
    use MyAppWeb, :live_view

    def render(assigns) do
      ~H"""
      <div>
        <button type="button" phx-click="save">Save</button>
        <a href={~p"/cards"}>Back</a>
        <input type="hidden" name="card[id]" value={@card.id} />
        <.live_file_input upload={@uploads.files} />
        <.button phx-click="x"><:text>Ok</:text></.button>
        <article>text</article>
        <select name="kind"><option>a</option></select>
      </div>
      """
    end
  end
  '''

  test "flags raw button, link and select but not hidden inputs, components or other tags" do
    @template
    |> to_source_file("lib/my_app_web/live/card_live.ex")
    |> run_check(RawHtmlElement)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.trigger) == ["<button", "<a", "<select"]
      assert Enum.map(issues, & &1.line_no) == [7, 8, 13]
    end)
  end

  test "skips component modules" do
    @template
    |> to_source_file("lib/my_app_web/components/buttons.ex")
    |> run_check(RawHtmlElement)
    |> refute_issues()
  end
end
