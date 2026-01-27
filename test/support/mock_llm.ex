defmodule FlowStone.AI.Test.MockLLM do
  @moduledoc false
  @behaviour PortfolioCore.Ports.LLM

  @impl true
  def complete(_messages, opts) do
    response_fn = Keyword.get(opts, :response_fn)
    prompt = Keyword.get(opts, :_prompt, "")

    result =
      if is_function(response_fn) do
        response_fn.(prompt)
      else
        %{
          content: Keyword.get(opts, :mock_content, "mock response"),
          model: "mock-model",
          usage: %{input_tokens: 10, output_tokens: 5},
          finish_reason: :stop
        }
      end

    case result do
      {:ok, _} = ok -> ok
      {:error, _} = err -> err
      %{} = map -> {:ok, map}
    end
  end

  @impl true
  def stream(_messages, _opts), do: {:ok, []}

  @impl true
  def supported_models, do: ["mock-model"]

  @impl true
  def model_info(_model), do: %{context_window: 4096, max_output: 1024, supports_tools: false}
end
