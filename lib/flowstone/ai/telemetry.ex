defmodule FlowStone.AI.Telemetry do
  @moduledoc """
  Bridges portfolio_index telemetry events to FlowStone's telemetry system.

  Attaches handlers that forward `[:portfolio_index, *]` events to
  `[:flowstone, :ai, *]` namespace for unified observability.

  ## Usage

  Call `attach/0` once during application startup:

      def start(_type, _args) do
        FlowStone.AI.Telemetry.attach()
        # ... rest of startup
      end

  ## Events

  The following events are bridged:

    * `[:portfolio_index, :llm, :complete, :start]` -> `[:flowstone, :ai, :generate, :start]`
    * `[:portfolio_index, :llm, :complete, :stop]` -> `[:flowstone, :ai, :generate, :stop]`
    * `[:portfolio_index, :llm, :complete, :exception]` -> `[:flowstone, :ai, :generate, :exception]`
    * `[:portfolio_index, :embedder, :embed, :start]` -> `[:flowstone, :ai, :embed, :start]`
    * `[:portfolio_index, :embedder, :embed, :stop]` -> `[:flowstone, :ai, :embed, :stop]`
    * `[:portfolio_index, :embedder, :embed, :exception]` -> `[:flowstone, :ai, :embed, :exception]`
    * `[:portfolio_index, :agent_session, :execute, :start]` -> `[:flowstone, :ai, :agent, :start]`
    * `[:portfolio_index, :agent_session, :execute, :stop]` -> `[:flowstone, :ai, :agent, :stop]`

  ## Measurements

  All measurements from the original portfolio_index events are preserved.

  ## Metadata

  All metadata from the original portfolio_index events are preserved.
  """

  @handler_id "flowstone-ai-portfolio-telemetry-bridge"

  @source_events [
    [:portfolio_index, :llm, :complete, :start],
    [:portfolio_index, :llm, :complete, :stop],
    [:portfolio_index, :llm, :complete, :exception],
    [:portfolio_index, :embedder, :embed, :start],
    [:portfolio_index, :embedder, :embed, :stop],
    [:portfolio_index, :embedder, :embed, :exception],
    [:portfolio_index, :agent_session, :execute, :start],
    [:portfolio_index, :agent_session, :execute, :stop]
  ]

  @event_mapping %{
    [:portfolio_index, :llm, :complete, :start] => [:flowstone, :ai, :generate, :start],
    [:portfolio_index, :llm, :complete, :stop] => [:flowstone, :ai, :generate, :stop],
    [:portfolio_index, :llm, :complete, :exception] => [:flowstone, :ai, :generate, :exception],
    [:portfolio_index, :embedder, :embed, :start] => [:flowstone, :ai, :embed, :start],
    [:portfolio_index, :embedder, :embed, :stop] => [:flowstone, :ai, :embed, :stop],
    [:portfolio_index, :embedder, :embed, :exception] => [:flowstone, :ai, :embed, :exception],
    [:portfolio_index, :agent_session, :execute, :start] => [:flowstone, :ai, :agent, :start],
    [:portfolio_index, :agent_session, :execute, :stop] => [:flowstone, :ai, :agent, :stop]
  }

  @doc """
  Attach telemetry handlers to bridge portfolio_index events to FlowStone namespace.
  """
  @spec attach() :: :ok | {:error, term()}
  def attach do
    :telemetry.attach_many(
      @handler_id,
      @source_events,
      &handle_event/4,
      %{mapping: @event_mapping}
    )

    :ok
  rescue
    _ -> :ok
  end

  @doc """
  Detach the telemetry handlers.
  """
  @spec detach() :: :ok | {:error, :not_found}
  def detach do
    case :telemetry.detach(@handler_id) do
      :ok -> :ok
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  @doc false
  def handle_event(event, measurements, metadata, %{mapping: mapping}) do
    case Map.get(mapping, event) do
      nil -> :ok
      target_event -> :telemetry.execute(target_event, measurements, metadata)
    end
  end
end
