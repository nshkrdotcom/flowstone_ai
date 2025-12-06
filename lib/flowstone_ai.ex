defmodule FlowStone.AI do
  @moduledoc """
  FlowStone integration for altar_ai.

  Provides AI capabilities as a FlowStone Resource, enabling
  AI-powered data pipeline assets with automatic provider
  fallback and unified telemetry.

  ## Installation

  Add to mix.exs:

      {:flowstone_ai, path: "../flowstone_ai"}

  ## Configuration

      # config/config.exs
      config :flowstone_ai,
        adapter: Altar.AI.Adapters.Gemini,
        adapter_opts: [api_key: System.get_env("GEMINI_API_KEY")]

  ## Usage

  Register the AI resource and use in assets:

      FlowStone.Resources.register(:ai, FlowStone.AI.Resource, [])

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

  FlowStone.AI bridges altar_ai telemetry events to FlowStone's telemetry system.
  Call `setup_telemetry/0` during application startup to enable this bridge.

      def start(_type, _args) do
        FlowStone.AI.setup_telemetry()
        # ... rest of startup
      end

  Events are forwarded from `[:altar, :ai, ...]` to `[:flowstone, :ai, ...]`.
  """

  @doc """
  Initialize the AI resource with the given options.

  Delegates to `FlowStone.AI.Resource.init/1` for manual initialization.
  When used as a FlowStone Resource, the `setup/1` callback is used instead.
  """
  defdelegate resource_init(opts), to: FlowStone.AI.Resource, as: :init

  @doc """
  Set up telemetry bridge to forward altar_ai events to FlowStone's telemetry namespace.

  Should be called once during application startup.
  """
  def setup_telemetry do
    FlowStone.AI.Telemetry.attach()
  end
end
