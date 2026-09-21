defmodule PlangoraElixirRules.Check.Ash.RequireAshExprTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.RequireAshExpr

  test "flags require Ash.Expr and Ash.Query.Exists.new" do
    """
    defmodule MyApp.Checks.ProjectMember do
      use Ash.Policy.FilterCheck
      require Ash.Expr

      def filter(actor, _context, opts) do
        inner = Ash.Expr.expr(user_id == ^actor.id)
        Ash.Query.Exists.new(opts[:path] ++ [:accesses], inner)
      end
    end
    """
    |> to_source_file("lib/my_app/checks/project_member.ex")
    |> run_check(RequireAshExpr)
    |> assert_issues(2)
  end
end
