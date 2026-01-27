defmodule FlowStone.AI.Test.ConfigurableMockEmbedder do
  @moduledoc """
  A configurable mock Embedder that reads responses from the process dictionary.

  Usage:

      Process.put(:mock_embedder_response, {:ok, %{vector: [...], ...}})
      Process.put(:mock_embedder_batch_response, {:ok, %{embeddings: [...], total_tokens: 10}})
  """
  @behaviour PortfolioCore.Ports.Embedder

  @impl true
  def embed(_text, _opts) do
    case Process.get(:mock_embedder_response) do
      nil ->
        {:ok, %{vector: [0.1, 0.2, 0.3], model: "mock-embedder", dimensions: 3, token_count: 5}}

      {:error, _} = err ->
        err

      {:ok, _} = ok ->
        ok
    end
  end

  @impl true
  def embed_batch(texts, _opts) do
    case Process.get(:mock_embedder_batch_response) do
      nil ->
        embeddings =
          Enum.map(texts, fn _text ->
            %{vector: [0.1, 0.2, 0.3], model: "mock-embedder", dimensions: 3, token_count: 5}
          end)

        {:ok, %{embeddings: embeddings, total_tokens: length(texts) * 5}}

      {:error, _} = err ->
        err

      {:ok, _} = ok ->
        ok
    end
  end

  @impl true
  def dimensions(_model), do: 3

  @impl true
  def supported_models, do: ["mock-embedder"]
end
