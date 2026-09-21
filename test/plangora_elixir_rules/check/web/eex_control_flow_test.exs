defmodule PlangoraElixirRules.Check.Web.EexControlFlowTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Web.EexControlFlow

  test "flags EEx if/for blocks in ~H" do
    ~S'''
    defmodule MyAppWeb.Form do
      use MyAppWeb, :html

      def form(assigns) do
        ~H"""
        <%= if @action == :new do %>
          <p>New</p>
        <% end %>
        <p :if={@x}>ok</p>
        <%= for item <- @items do %>{item}<% end %>
        """
      end
    end
    '''
    |> to_source_file("lib/my_app_web/form.ex")
    |> run_check(EexControlFlow)
    |> assert_issues(2)
  end
end
