defmodule FlowStone.AI.Telemetry do
  @moduledoc """
  Bridges altar_ai telemetry events to FlowStone's telemetry system.

  Attaches handlers that forward `[:altar, :ai, *]` events to
  `[:flowstone, :ai, *]` namespace for unified observability.

  ## Usage

  Call `attach/0` once during application startup:

      def start(_type, _args) do
        FlowStone.AI.Telemetry.attach()
        # ... rest of startup
      end

  ## Events

  The following events are bridged:

    * `[:altar, :ai, :generate, :start]` -> `[:flowstone, :ai, :generate, :start]`
    * `[:altar, :ai, :generate, :stop]` -> `[:flowstone, :ai, :generate, :stop]`
    * `[:altar, :ai, :generate, :exception]` -> `[:flowstone, :ai, :generate, :exception]`
    * `[:altar, :ai, :embed, :start]` -> `[:flowstone, :ai, :embed, :start]`
    * `[:altar, :ai, :embed, :stop]` -> `[:flowstone, :ai, :embed, :stop]`
    * `[:altar, :ai, :embed, :exception]` -> `[:flowstone, :ai, :embed, :exception]`

  ## Measurements

  All measurements from the original altar_ai events are preserved:

    * `:start` events: `%{system_time: integer()}`
    * `:stop` events: `%{duration: integer()}`
    * `:exception` events: `%{duration: integer()}`

  ## Metadata

  All metadata from the original altar_ai events are preserved, including:

    * `:adapter` - The adapter being used
    * `:prompt` or `:text` - The input being processed
    * `:kind`, `:reason`, `:stacktrace` - For exception events
  """

  require Logger

  @events [
    [:altar, :ai, :generate, :start],
    [:altar, :ai, :generate, :stop],
    [:altar, :ai, :generate, :exception],
    [:altar, :ai, :embed, :start],
    [:altar, :ai, :embed, :stop],
    [:altar, :ai, :embed, :exception]
  ]

  @doc """
  Attach telemetry handlers to bridge altar_ai events to FlowStone namespace.

  This function is idempotent - calling it multiple times will not create
  duplicate handlers.

  Returns `:ok` on success.
  """
  @spec attach() :: :ok
  def attach do
    :telemetry.attach_many(
      "flowstone-ai-bridge",
      @events,
      &handle_event/4,
      nil
    )

    Logger.debug("FlowStone.AI telemetry bridge attached")
    :ok
  end

  @doc """
  Detach the telemetry handlers.

  Useful for testing or if you need to disable the bridge.
  """
  @spec detach() :: :ok | {:error, :not_found}
  def detach do
    :telemetry.detach("flowstone-ai-bridge")
  end

  # Private event handler

  defp handle_event([:altar, :ai | rest], measurements, metadata, _config) do
    :telemetry.execute([:flowstone, :ai | rest], measurements, metadata)
  end
end
