defmodule PlangoraElixirRules.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Plangora/plangora_elixir_rules"

  def project do
    [
      app: :plangora_elixir_rules,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: false,
      deps: [],
      description: "Plangora's Elixir, Ash and Phoenix house rules, delivered through usage_rules.",
      package: package(),
      source_url: @source_url
    ]
  end

  def application, do: []

  defp package do
    [
      files: ~w(mix.exs README.md usage-rules.md usage-rules),
      links: %{"GitHub" => @source_url}
    ]
  end
end
