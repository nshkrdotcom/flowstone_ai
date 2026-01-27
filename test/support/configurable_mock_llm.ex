defmodule FlowStone.AI.Test.ConfigurableMockLLM do
  @moduledoc """
  A configurable mock LLM that reads responses from the process dictionary.

  Usage:

      Process.put(:mock_llm_response, {:ok, %{content: "hello", ...}})
      # or
      Process.put(:mock_llm_response, fn messages, opts -> {:ok, %{...}} end)
  """
  @behaviour PortfolioCore.Ports.LLM

  @impl true
  def complete(messages, opts) do
    case Process.get(:mock_llm_response) do
      nil ->
        {:ok,
         %{
           content: "default mock response",
           model: "mock-model",
           usage: %{input_tokens: 10, output_tokens: 5},
           finish_reason: :stop
         }}

      {:error, _} = err ->
        err

      fun when is_function(fun, 2) ->
        fun.(messages, opts)

      fun when is_function(fun, 1) ->
        # Extract last user message content for backward compat
        prompt =
          messages
          |> Enum.filter(&(&1.role == :user))
          |> List.last()
          |> case do
            nil -> ""
            msg -> msg.content
          end

        fun.(prompt)

      {:ok, _} = ok ->
        ok
    end
  end

  @impl true
  def stream(_messages, _opts), do: {:ok, []}

  @impl true
  def supported_models, do: ["mock-model"]

  @impl true
  def model_info(_model), do: %{context_window: 4096, max_output: 1024, supports_tools: false}
end
