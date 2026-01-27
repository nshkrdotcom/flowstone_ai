defmodule FlowStone.AI.Test.MockAgentSession do
  @moduledoc false
  @behaviour PortfolioCore.Ports.AgentSession

  @impl true
  def provider_name, do: "mock"

  @impl true
  def capabilities do
    {:ok, [%{name: "chat", type: :tool, enabled: true}]}
  end

  @impl true
  def start_session(_agent_id, _opts) do
    {:ok, "mock_session_#{System.unique_integer([:positive])}"}
  end

  @impl true
  def execute(_session_id, _input, _opts) do
    {:ok,
     %{
       output: "mock agent output",
       token_usage: %{input_tokens: 10, output_tokens: 20},
       turn_count: 1,
       events: []
     }}
  end

  @impl true
  def cancel(_session_id, run_id) do
    {:ok, run_id}
  end

  @impl true
  def end_session(_session_id), do: :ok

  @impl true
  def validate_config(_config), do: :ok
end
