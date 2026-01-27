defmodule FlowStone.AI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/flowstone_ai"

  def project do
    [
      app: :flowstone_ai,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      name: "FlowStoneAI",
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],

      # Dialyzer
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies (path for local dev)
      {:flowstone, path: "../flowstone"},
      {:portfolio_core, path: "../portfolio_core"},
      {:portfolio_index, path: "../portfolio_index"},

      # Test dependencies
      {:stream_data, "~> 1.0", only: :test},
      {:supertester, path: "../supertester", only: :test},

      # Dev/docs dependencies
      {:ex_doc, "~> 0.40.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp description do
    """
    FlowStone integration for portfolio AI providers - AI-powered data pipeline assets.
    Provides FlowStone.AI.Resource for unified AI access and FlowStone.AI.Assets
    DSL helpers (classify_each, enrich_each, embed_each) with telemetry bridging.
    Delegates to portfolio_core/portfolio_index for LLM, Embedder, and AgentSession support.
    """
  end

  defp package do
    [
      name: "flowstone_ai",
      maintainers: ["nshkrdotcom"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md assets),
      exclude_patterns: [
        "priv/plts",
        ".DS_Store"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "FlowStoneAI",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      logo: "assets/flowstone_ai.svg",
      assets: %{"assets" => "assets"},
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      groups_for_modules: [
        "Core API": [FlowStone.AI],
        Resource: [FlowStone.AI.Resource],
        "DSL Helpers": [FlowStone.AI.Assets],
        Utilities: [FlowStone.AI.Telemetry]
      ]
    ]
  end
end
