defmodule FlowStone.AI.Test.MockEmbedder do
  @moduledoc false
  @behaviour PortfolioCore.Ports.Embedder

  @impl true
  def embed(_text, _opts) do
    {:ok, %{vector: [0.1, 0.2, 0.3], model: "mock-embedder", dimensions: 3, token_count: 5}}
  end

  @impl true
  def embed_batch(texts, opts) do
    embeddings =
      Enum.map(texts, fn _text ->
        {:ok, result} = embed("", opts)
        result
      end)

    {:ok, %{embeddings: embeddings, total_tokens: length(texts) * 5}}
  end

  @impl true
  def dimensions(_model), do: 3

  @impl true
  def supported_models, do: ["mock-embedder"]
end
