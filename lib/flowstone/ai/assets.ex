defmodule FlowStone.AI.Assets do
  @moduledoc """
  DSL helpers for common AI-powered asset patterns.

  This module provides convenient helpers for integrating AI capabilities
  into FlowStone assets, making it easy to classify, enrich, and embed data
  within your pipeline. Delegates to portfolio_core/portfolio_index adapters
  via `FlowStone.AI.Resource`.

  ## Examples

      # Classify feedback
      asset :classified_feedback do
        depends_on [:raw_feedback]
        requires [:ai]
        execute fn ctx, %{raw_feedback: feedback} ->
          FlowStone.AI.Assets.classify_each(
            ctx.resources.ai,
            feedback,
            & &1.text,
            ["positive", "negative", "neutral"]
          )
        end
      end

      # Enrich with AI-generated summaries
      asset :enriched_articles do
        depends_on [:articles]
        requires [:ai]
        execute fn ctx, %{articles: articles} ->
          FlowStone.AI.Assets.enrich_each(
            ctx.resources.ai,
            articles,
            fn article -> "Summarize in 2 sentences: \#{article.body}" end
          )
        end
      end

      # Generate embeddings for search
      asset :searchable_docs do
        depends_on [:documents]
        requires [:ai]
        execute fn ctx, %{documents: docs} ->
          FlowStone.AI.Assets.embed_each(
            ctx.resources.ai,
            docs,
            & &1.content
          )
        end
      end
  """

  alias FlowStone.AI.Resource

  @doc """
  Classify each item in a collection using AI.

  Applies the `text_fn` to extract text from each item, classifies it
  using the LLM into one of the given labels, and merges the classification
  result back into the item.

  ## Parameters

    * `resource` - The AI resource
    * `items` - List of items to classify
    * `text_fn` - Function to extract text from each item
    * `labels` - List of classification labels
    * `opts` - Additional options for the LLM

  ## Returns

    * `{:ok, classified_items}` - Items with `:classification` and `:confidence` added
    * `{:error, reason}` - On failure

  """
  @spec classify_each(Resource.t(), list(), (term() -> String.t()), [String.t()], keyword()) ::
          {:ok, list()} | {:error, term()}
  def classify_each(resource, items, text_fn, labels, opts \\ [])

  def classify_each(_resource, [], _text_fn, _labels, _opts), do: {:ok, []}

  def classify_each(resource, items, text_fn, labels, opts) do
    results =
      Enum.map(items, fn item ->
        text = text_fn.(item)

        case Resource.classify(resource, text, labels, opts) do
          {:ok, classification} ->
            item
            |> Map.put(:classification, classification.label)
            |> Map.put(:confidence, classification.confidence)

          {:error, _} ->
            item
        end
      end)

    {:ok, results}
  end

  @doc """
  Enrich each item in a collection with AI-generated content.

  Applies the `prompt_fn` to generate a prompt for each item, calls the LLM,
  and merges the result as `:ai_enrichment` into the item.

  ## Parameters

    * `resource` - The AI resource
    * `items` - List of items to enrich
    * `prompt_fn` - Function that takes an item and returns a prompt string
    * `opts` - Additional options for the LLM

  ## Returns

    * `{:ok, enriched_items}` - Items with `:ai_enrichment` added
    * `{:error, reason}` - On failure

  """
  @spec enrich_each(Resource.t(), list(), (term() -> String.t()), keyword()) ::
          {:ok, list()} | {:error, term()}
  def enrich_each(resource, items, prompt_fn, opts \\ [])

  def enrich_each(_resource, [], _prompt_fn, _opts), do: {:ok, []}

  def enrich_each(resource, items, prompt_fn, opts) do
    results =
      Enum.map(items, fn item ->
        prompt = prompt_fn.(item)

        case Resource.generate(resource, prompt, opts) do
          {:ok, response} ->
            Map.put(item, :ai_enrichment, response.content)

          {:error, _} ->
            item
        end
      end)

    {:ok, results}
  end

  @doc """
  Generate embeddings for each item in a collection.

  Applies the `text_fn` to extract text from each item, generates embeddings
  in batch using the Embedder adapter, and merges each embedding as `:embedding`
  into the corresponding item.

  ## Parameters

    * `resource` - The AI resource
    * `items` - List of items to embed
    * `text_fn` - Function to extract text from each item
    * `opts` - Additional options for the embedder

  ## Returns

    * `{:ok, embedded_items}` - Items with `:embedding` added
    * `{:error, reason}` - On failure

  """
  @spec embed_each(Resource.t(), list(), (term() -> String.t()), keyword()) ::
          {:ok, list()} | {:error, term()}
  def embed_each(resource, items, text_fn, opts \\ [])

  def embed_each(_resource, [], _text_fn, _opts), do: {:ok, []}

  def embed_each(resource, items, text_fn, opts) do
    texts = Enum.map(items, text_fn)

    case Resource.batch_embed(resource, texts, opts) do
      {:ok, vectors} ->
        results =
          items
          |> Enum.zip(vectors)
          |> Enum.map(fn {item, vector} ->
            Map.put(item, :embedding, vector)
          end)

        {:ok, results}

      {:error, _} = error ->
        error
    end
  end
end
