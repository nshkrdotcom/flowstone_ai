defmodule FlowStone.AI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/flowstone_ai"

  def project do
    [
      app: :flowstone_ai,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "FlowStone.AI",
      description: "FlowStone integration for altar_ai - AI-powered data pipeline assets",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),

      # Package
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies
      {:altar_ai, path: "../altar_ai"},
      {:flowstone, path: "../flowstone"},

      # Test dependencies
      {:supertester, path: "../supertester", only: :test},

      # Dev/docs dependencies
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      logo: "assets/flowstone_ai.svg",
      assets: "assets"
    ]
  end

  defp package do
    [
      maintainers: ["nshkr"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
