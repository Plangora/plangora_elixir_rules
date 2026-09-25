defmodule PlangoraElixirRules.MixProject do
  use Mix.Project

  @version "0.3.1"
  @source_url "https://github.com/Plangora/plangora_elixir_rules"

  def project do
    [
      app: :plangora_elixir_rules,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: false,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description:
        "Plangora's Elixir, Ash and Phoenix house rules: usage_rules content for agents " <>
          "and a Credo plugin that enforces the mechanical ones.",
      package: package(),
      source_url: @source_url
    ]
  end

  def application, do: [extra_applications: []]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.7", runtime: false},
      {:ash_credo, "~> 0.17", runtime: false}
    ]
  end

  defp package do
    [
      files: ~w(mix.exs README.md lib usage-rules.md usage-rules),
      links: %{"GitHub" => @source_url}
    ]
  end
end
