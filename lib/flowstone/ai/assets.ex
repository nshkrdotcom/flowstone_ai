defmodule FlowStone.AI.Assets do
  @moduledoc """
  DSL helpers for common AI-powered asset patterns.

  This module provides convenient helpers for integrating AI capabilities
  into FlowStone assets, making it easy to classify, enrich, and embed data
  within your pipeline.

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

  Takes a collection of items, extracts text from each using `text_fn`,
  and classifies it into one of the provided labels. The classification
  and confidence are added to each item.

  ## Parameters

    * `resource` - The FlowStone.AI.Resource instance
    * `items` - Collection of items to classify
    * `text_fn` - Function to extract text from each item
    * `labels` - List of classification labels
    * `opts` - Additional options to pass to the classifier (optional)

  ## Returns

    * `{:ok, classified_items}` - Items with `:classification` and `:confidence` fields added
    * Items that fail classification will have `:classification` set to `:unknown`

  ## Examples

      FlowStone.AI.Assets.classify_each(
        resource,
        feedback_items,
        & &1.comment,
        ["bug", "feature_request", "question"]
      )
  """
  @spec classify_each(
          Resource.t(),
          list(map()),
          (map() -> String.t()),
          list(String.t()),
          keyword()
        ) ::
          {:ok, list(map())}
  def classify_each(resource, items, text_fn, labels, opts \\ []) do
    results =
      Enum.map(items, fn item ->
        text = text_fn.(item)

        case Resource.classify(resource, text, labels, opts) do
          {:ok, classification} ->
            Map.merge(item, %{
              classification: classification.label,
              confidence: classification.confidence
            })

          {:error, _} ->
            Map.put(item, :classification, :unknown)
        end
      end)

    {:ok, results}
  end

  @doc """
  Enrich each item in a collection with AI-generated content.

  Takes a collection of items, generates a prompt for each using `prompt_fn`,
  and adds the AI response as `:ai_enrichment` field.

  ## Parameters

    * `resource` - The FlowStone.AI.Resource instance
    * `items` - Collection of items to enrich
    * `prompt_fn` - Function to generate prompt from each item
    * `opts` - Additional options to pass to the generator (optional)

  ## Returns

    * `{:ok, enriched_items}` - Items with `:ai_enrichment` field added
    * Items that fail enrichment remain unchanged

  ## Examples

      FlowStone.AI.Assets.enrich_each(
        resource,
        products,
        fn product -> "Write a catchy tagline for: \#{product.name}" end
      )
  """
  @spec enrich_each(Resource.t(), list(map()), (map() -> String.t()), keyword()) ::
          {:ok, list(map())}
  def enrich_each(resource, items, prompt_fn, opts \\ []) do
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

  Takes a collection of items, extracts text from each using `text_fn`,
  generates embeddings, and adds them as `:embedding` field.

  Uses batch embedding for better performance when the adapter supports it.

  ## Parameters

    * `resource` - The FlowStone.AI.Resource instance
    * `items` - Collection of items to embed
    * `text_fn` - Function to extract text from each item
    * `opts` - Additional options to pass to the embedder (optional)

  ## Returns

    * `{:ok, embedded_items}` - Items with `:embedding` field added
    * `{:error, reason}` - If batch embedding fails

  ## Examples

      FlowStone.AI.Assets.embed_each(
        resource,
        documents,
        & &1.content
      )
  """
  @spec embed_each(Resource.t(), list(map()), (map() -> String.t()), keyword()) ::
          {:ok, list(map())} | {:error, term()}
  def embed_each(resource, items, text_fn, opts \\ []) do
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
