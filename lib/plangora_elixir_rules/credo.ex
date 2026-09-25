defmodule PlangoraElixirRules.Credo do
  @moduledoc """
  Credo plugin that enforces the mechanical half of the Plangora house rules.

  Add it after `AshCredo` in `.credo.exs`:

      %{configs: [%{name: "default", plugins: [{AshCredo, []}, {PlangoraElixirRules.Credo, []}]}]}

  It turns on the `AshCredo` checks that match our rules (they ship disabled),
  keeps Credo's own `SinglePipe`, `ModuleDoc` and `Nesting` on, and adds the
  checks under `PlangoraElixirRules.Check` for what neither covers: foreign
  keys in `accept`, `attribute_writable?`, missing archival and paper trail,
  missing `public? true`, `require Ash.Expr` in checks, enum labels without
  gettext, raw HTML elements and EEx control flow in `~H`, `Calendar.strftime`
  in the web layer, and the test conventions.

  Disable or tune any of them in the project's `.credo.exs` the usual way:

      checks: %{extra: [{PlangoraElixirRules.Check.Ash.MissingPublic, ignored_names: [:secret]}]}

  Checks that read the resource DSL need a compiled project, so run Credo
  through an alias such as `lint: ["compile", "credo --strict"]`.
  """

  import Credo.Plugin

  @config_file """
  %{
    configs: [
      %{
        name: "default",
        checks: %{
          extra: [
            # Credo's own checks we rely on (on by default, listed so a
            # project that trims its defaults keeps them).
            {Credo.Check.Readability.SinglePipe, []},
            {Credo.Check.Readability.ModuleDoc, []},
            {Credo.Check.Refactor.Nesting, []},

            # AshCredo checks that match a house rule; they ship disabled.
            {AshCredo.Check.Warning.AuthorizeFalse, []},
            {AshCredo.Check.Warning.ActorOnCallOptions, []},
            {AshCredo.Check.Warning.WildcardAcceptOnAction, []},
            {AshCredo.Check.Warning.SensitiveAttributeExposed, []},
            {AshCredo.Check.Warning.OverlyPermissivePolicy, []},
            {AshCredo.Check.Warning.AuthorizerWithoutPolicies, []},
            {AshCredo.Check.Readability.BelongsToMissingAllowNil, []},
            {AshCredo.Check.Design.MissingTimestamps, []},

            # Ours.
            {PlangoraElixirRules.Check.Ash.ForeignKeyInAccept, []},
            {PlangoraElixirRules.Check.Ash.AttributeWritable, []},
            {PlangoraElixirRules.Check.Ash.StandaloneForeignKeyAttribute, []},
            {PlangoraElixirRules.Check.Ash.MissingArchivalOrPaperTrail, []},
            {PlangoraElixirRules.Check.Ash.MissingPublic, []},
            {PlangoraElixirRules.Check.Ash.RequireAshExpr, []},
            {PlangoraElixirRules.Check.Ash.EnumLabelWithoutGettext, []},
            {PlangoraElixirRules.Check.Web.RawHtmlElement, []},
            {PlangoraElixirRules.Check.Web.EexControlFlow, []},
            {PlangoraElixirRules.Check.Web.StrftimeInWeb, []},
            {PlangoraElixirRules.Check.Test.FactoryModulePrefix, []},
            {PlangoraElixirRules.Check.Test.AsyncFalse, []}
          ]
        }
      }
    ]
  }
  """

  def init(exec), do: register_default_config(exec, @config_file)
end
