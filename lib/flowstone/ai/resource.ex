defmodule FlowStone.AI.Resource do
  @moduledoc """
  FlowStone Resource that provides AI capabilities to assets.

  > **Deprecation Notice**: This module is deprecated in favor of using
  > `Altar.AI.Integrations.FlowStone` directly from the `altar_ai` package.
  > All functions delegate to the unified integration while maintaining
  > backward compatibility.

  ## Usage

  In your pipeline:

      asset :enriched do
        requires [:ai]
        execute fn ctx, %{raw: data} ->
          {:ok, result} = FlowStone.AI.Resource.generate(ctx.resources.ai, "classify: \#{data}")
          {:ok, Map.put(data, :classification, result.content)}
        end
      end

  ## Configuration

      config :flowstone_ai,
        adapter: Altar.AI.Adapters.Composite,
        adapter_opts: []

  The resource will use the configured adapter, defaulting to `Altar.AI.Adapters.Composite`
  for automatic provider fallback.
  """

  @behaviour FlowStone.Resource

  alias Altar.AI.Integrations.FlowStone, as: Integration

  @type t :: Integration.t()

  @impl true
  @doc """
  Set up the AI resource.

  This is the FlowStone.Resource callback. Delegates to `Altar.AI.Integrations.FlowStone.setup/1`.
  """
  def setup(config) when is_map(config) do
    config
    |> Map.to_list()
    |> Integration.setup()
  end

  @deprecated "Use Altar.AI.Integrations.FlowStone.init/1 instead"
  @doc """
  Initialize the AI resource.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.init/1` instead.
  """
  defdelegate init(opts \\ []), to: Integration

  @doc false
  @spec legacy_init(keyword()) :: {:ok, t()} | {:error, term()}
  def legacy_init(opts \\ []), do: init(opts)

  @impl true
  @doc """
  Teardown the AI resource.

  Delegates to `Altar.AI.Integrations.FlowStone.teardown/1`.
  """
  defdelegate teardown(resource), to: Integration

  @impl true
  @doc """
  Check the health of the AI resource.

  Delegates to `Altar.AI.Integrations.FlowStone.health_check/1`.
  """
  defdelegate health_check(resource), to: Integration

  @deprecated "Use Altar.AI.Integrations.FlowStone.generate/3 instead"
  @doc """
  Generate text using the AI adapter.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.generate/3` instead.
  """
  defdelegate generate(resource, prompt, opts \\ []), to: Integration

  @doc false
  @spec legacy_generate(t(), String.t(), keyword()) ::
          {:ok, Altar.AI.Response.t()} | {:error, term()}
  def legacy_generate(resource, prompt, opts \\ []), do: generate(resource, prompt, opts)

  @deprecated "Use Altar.AI.Integrations.FlowStone.embed/3 instead"
  @doc """
  Generate embeddings for text.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.embed/3` instead.
  """
  defdelegate embed(resource, text, opts \\ []), to: Integration

  @doc false
  @spec legacy_embed(t(), String.t(), keyword()) :: {:ok, [number()]} | {:error, term()}
  def legacy_embed(resource, text, opts \\ []), do: embed(resource, text, opts)

  @deprecated "Use Altar.AI.Integrations.FlowStone.batch_embed/3 instead"
  @doc """
  Generate embeddings for multiple texts in batch.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.batch_embed/3` instead.
  """
  defdelegate batch_embed(resource, texts, opts \\ []), to: Integration

  @doc false
  @spec legacy_batch_embed(t(), [String.t()], keyword()) ::
          {:ok, [[number()]]} | {:error, term()}
  def legacy_batch_embed(resource, texts, opts \\ []), do: batch_embed(resource, texts, opts)

  @deprecated "Use Altar.AI.Integrations.FlowStone.classify/4 instead"
  @doc """
  Classify text into one of the provided labels.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.classify/4` instead.
  """
  defdelegate classify(resource, text, labels, opts \\ []), to: Integration

  @doc false
  @spec legacy_classify(t(), String.t(), [String.t()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def legacy_classify(resource, text, labels, opts \\ []),
    do: classify(resource, text, labels, opts)

  @deprecated "Use Altar.AI.Integrations.FlowStone.capabilities/1 instead"
  @doc """
  Get the capabilities of the configured adapter.

  **Deprecated**: Use `Altar.AI.Integrations.FlowStone.capabilities/1` instead.
  """
  defdelegate capabilities(resource), to: Integration

  @doc false
  @spec legacy_capabilities(t()) :: map()
  def legacy_capabilities(resource), do: capabilities(resource)
end
