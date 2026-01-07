defmodule FlowStone.AI.Assets do
  @moduledoc """
  DSL helpers for common AI-powered asset patterns.

  > **Deprecation Notice**: This module is deprecated in favor of using
  > `Altar.AI.Integrations.FlowStone` directly from the `altar_ai` package.
  > The DSL helpers (`classify_each`, `enrich_each`, `embed_each`) are now
  > available directly on the integration module.

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

  alias Altar.AI.Integrations.FlowStone, as: Integration

  @deprecated "Use Altar.AI.Integrations.FlowStone.classify_each/5 instead"
  @doc """
  Classify each item in a collection using AI.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.classify_each/5` instead.
  """
  defdelegate classify_each(resource, items, text_fn, labels, opts \\ []), to: Integration

  @doc false
  @spec legacy_classify_each(
          Integration.t(),
          list(),
          (term() -> String.t()),
          [String.t()],
          keyword()
        ) ::
          {:ok, list()} | {:error, term()}
  def legacy_classify_each(resource, items, text_fn, labels, opts \\ []) do
    classify_each(resource, items, text_fn, labels, opts)
  end

  @deprecated "Use Altar.AI.Integrations.FlowStone.enrich_each/4 instead"
  @doc """
  Enrich each item in a collection with AI-generated content.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.enrich_each/4` instead.
  """
  defdelegate enrich_each(resource, items, prompt_fn, opts \\ []), to: Integration

  @doc false
  @spec legacy_enrich_each(Integration.t(), list(), (term() -> String.t()), keyword()) ::
          {:ok, list()} | {:error, term()}
  def legacy_enrich_each(resource, items, prompt_fn, opts \\ []) do
    enrich_each(resource, items, prompt_fn, opts)
  end

  @deprecated "Use Altar.AI.Integrations.FlowStone.embed_each/4 instead"
  @doc """
  Generate embeddings for each item in a collection.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.embed_each/4` instead.
  """
  defdelegate embed_each(resource, items, text_fn, opts \\ []), to: Integration

  @doc false
  @spec legacy_embed_each(Integration.t(), list(), (term() -> String.t()), keyword()) ::
          {:ok, list()} | {:error, term()}
  def legacy_embed_each(resource, items, text_fn, opts \\ []) do
    embed_each(resource, items, text_fn, opts)
  end
end
