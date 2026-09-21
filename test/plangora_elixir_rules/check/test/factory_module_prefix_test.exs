defmodule PlangoraElixirRules.Check.Test.FactoryModulePrefixTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Test.FactoryModulePrefix

  @source """
  defmodule MyApp.UserTest do
    use MyApp.DataCase, async: true

    test "x" do
      user = MyApp.Factory.user(admin: true) |> generate()
      other = generate(user())
      assert user.id != other.id
    end
  end
  """

  test "flags factory calls through the module in tests, not in support files" do
    @source
    |> to_source_file("test/my_app/user_test.exs")
    |> run_check(FactoryModulePrefix)
    |> assert_issue()

    @source
    |> to_source_file("test/support/factory.ex")
    |> run_check(FactoryModulePrefix)
    |> refute_issues()
  end
end
