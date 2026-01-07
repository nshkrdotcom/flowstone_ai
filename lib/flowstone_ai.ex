defmodule FlowStone.AI do
  @moduledoc """
  FlowStone integration for altar_ai.

  > **Deprecation Notice**: This package is deprecated in favor of using
  > `Altar.AI.Integrations.FlowStone` directly from the `altar_ai` package.
  > This module now delegates all functionality to the unified integration.
  >
  > **Migration Path**:
  > ```elixir
  > # Before (flowstone_ai)
  > {:ok, resource} = FlowStone.AI.resource_init(opts)
  > FlowStone.AI.setup_telemetry()
  >
  > # After (altar_ai)
  > {:ok, resource} = Altar.AI.Integrations.FlowStone.init(opts)
  > Altar.AI.Integrations.FlowStone.setup_telemetry()
  > ```

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

  @deprecated "Use Altar.AI.Integrations.FlowStone.init/1 instead"
  @doc """
  Initialize the AI resource with the given options.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.init/1` instead.
  """
  defdelegate resource_init(opts), to: Altar.AI.Integrations.FlowStone, as: :init

  @deprecated "Use Altar.AI.Integrations.FlowStone.setup_telemetry/0 instead"
  @doc """
  Set up telemetry bridge to forward altar_ai events to FlowStone's telemetry namespace.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.setup_telemetry/0` instead.
  """
  defdelegate setup_telemetry(), to: Altar.AI.Integrations.FlowStone
end
