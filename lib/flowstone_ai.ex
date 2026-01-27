defmodule FlowStone.AI do
  @moduledoc """
  FlowStone integration for portfolio AI providers.

  Provides AI capabilities as a FlowStone Resource, enabling
  AI-powered data pipeline assets with access to all portfolio
  LLM and Embedder providers, rate limiting, and agent session support.

  ## Installation

  Add to mix.exs:

      {:flowstone_ai, path: "../flowstone_ai"}

  ## Configuration

      # config/config.exs
      config :flowstone_ai,
        llm_adapter: PortfolioIndex.Adapters.LLM.Gemini,
        embedder_adapter: PortfolioIndex.Adapters.Embedder.Gemini,
        agent_session_adapter: PortfolioIndex.Adapters.AgentSession.Claude

  ## Usage

  Register the AI resource and use in assets:

      FlowStone.Resources.register(:ai, FlowStone.AI.Resource, %{})

      asset :enriched_data do
        requires [:ai]
        execute fn ctx, deps ->
          {:ok, response} = FlowStone.AI.Resource.generate(
            ctx.resources.ai,
            "Summarize: \#{deps.raw_data}"
          )
          {:ok, %{summary: response.content}}
        end
      end

  ## Telemetry

  FlowStone.AI bridges portfolio_index telemetry events to FlowStone's
  telemetry system. Call `setup_telemetry/0` during application startup.

      def start(_type, _args) do
        FlowStone.AI.setup_telemetry()
        # ... rest of startup
      end

  Events are forwarded from `[:portfolio_index, ...]` to `[:flowstone, :ai, ...]`.

  ## Available Providers

  Through portfolio_index, FlowStone.AI supports:

    * **LLM**: Gemini, Anthropic, OpenAI, Codex, Ollama, vLLM
    * **Embedder**: Gemini, OpenAI, Ollama, Bumblebee, Function
    * **AgentSession**: Claude, Codex
  """

  alias FlowStone.AI.Resource
  alias FlowStone.AI.Telemetry

  @doc """
  Initialize the AI resource with the given options.

  This is a convenience wrapper around `FlowStone.AI.Resource.setup/1`.
  """
  @spec resource_init(keyword()) :: {:ok, Resource.t()} | {:error, term()}
  def resource_init(opts \\ []) do
    opts
    |> Map.new()
    |> Resource.setup()
  end

  @doc """
  Set up telemetry bridge to forward portfolio_index events to FlowStone's
  telemetry namespace.
  """
  @spec setup_telemetry() :: :ok | {:error, term()}
  def setup_telemetry do
    Telemetry.attach()
  end
end
