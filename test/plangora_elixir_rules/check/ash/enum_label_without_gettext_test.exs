defmodule PlangoraElixirRules.Check.Ash.EnumLabelWithoutGettextTest do
  use Credo.Test.Case

  alias PlangoraElixirRules.Check.Ash.EnumLabelWithoutGettext

  test "flags plain string labels but not gettext ones" do
    """
    defmodule MyApp.RoleKind do
      use Gettext, backend: MyAppWeb.Gettext

      use Ash.Type.Enum,
        values: [
          staff: [label: gettext("Staff")],
          client: [label: "Client"],
          other: [label: "Other"]
        ]
    end
    """
    |> to_source_file("lib/my_app/role_kind.ex")
    |> run_check(EnumLabelWithoutGettext)
    |> assert_issues(2)
  end
end
