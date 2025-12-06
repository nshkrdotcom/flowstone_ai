defmodule FlowStone.AI.Resource do
  @moduledoc """
  FlowStone Resource that provides AI capabilities to assets.

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

  defstruct [:adapter, :opts]

  @type t :: %__MODULE__{
          adapter: struct(),
          opts: keyword()
        }

  @doc """
  Set up the AI resource.

  This is the FlowStone.Resource callback. For manual initialization, use `init/1`.

  ## Options

    * `:adapter` - The altar_ai adapter module to use (default: `Altar.AI.Adapters.Composite`)
    * `:adapter_opts` - Options to pass to the adapter initialization (default: `[]`)
  """
  @impl true
  def setup(config) when is_map(config) do
    # Convert map config to keyword list for init
    opts = Map.to_list(config)
    init(opts)
  end

  @doc """
  Initialize the AI resource.

  ## Options

    * `:adapter` - The altar_ai adapter module to use (default: `Altar.AI.Adapters.Composite`)
    * `:adapter_opts` - Options to pass to the adapter initialization (default: `[]`)

  ## Examples

      {:ok, resource} = FlowStone.AI.Resource.init()

      {:ok, resource} = FlowStone.AI.Resource.init(
        adapter: Altar.AI.Adapters.Gemini,
        adapter_opts: [api_key: "..."]
      )
  """
  def init(opts \\ []) do
    adapter_mod = Keyword.get(opts, :adapter, get_config(:adapter, Altar.AI.Adapters.Composite))
    adapter_opts = Keyword.get(opts, :adapter_opts, get_config(:adapter_opts, []))

    adapter =
      if adapter_mod == Altar.AI.Adapters.Composite do
        Altar.AI.Adapters.Composite.default()
      else
        adapter_mod.new(adapter_opts)
      end

    {:ok, %__MODULE__{adapter: adapter, opts: opts}}
  end

  @impl true
  def teardown(_resource), do: :ok

  @impl true
  def health_check(%__MODULE__{adapter: adapter}) do
    # Check if adapter has basic capabilities
    case Altar.AI.capabilities(adapter) do
      %{generate: true} -> :healthy
      _ -> {:unhealthy, :no_capabilities}
    end
  rescue
    _ -> {:unhealthy, :adapter_error}
  end

  @doc """
  Generate text using the AI adapter.

  Delegates to `Altar.AI.generate/3`.

  ## Examples

      {:ok, response} = FlowStone.AI.Resource.generate(resource, "Explain quantum computing")
      IO.puts(response.content)
  """
  @spec generate(t(), String.t(), keyword()) :: {:ok, Altar.AI.Response.t()} | {:error, term()}
  def generate(%__MODULE__{adapter: adapter}, prompt, opts \\ []) do
    Altar.AI.generate(adapter, prompt, opts)
  end

  @doc """
  Generate embeddings for text.

  Delegates to `Altar.AI.embed/3`.

  ## Examples

      {:ok, vector} = FlowStone.AI.Resource.embed(resource, "Hello world")
      length(vector) # => 768 (or adapter-specific dimension)
  """
  @spec embed(t(), String.t(), keyword()) :: {:ok, list(float())} | {:error, term()}
  def embed(%__MODULE__{adapter: adapter}, text, opts \\ []) do
    Altar.AI.embed(adapter, text, opts)
  end

  @doc """
  Generate embeddings for multiple texts in batch.

  Delegates to `Altar.AI.batch_embed/3`.

  ## Examples

      {:ok, vectors} = FlowStone.AI.Resource.batch_embed(resource, ["text1", "text2"])
      length(vectors) # => 2
  """
  @spec batch_embed(t(), list(String.t()), keyword()) ::
          {:ok, list(list(float()))} | {:error, term()}
  def batch_embed(%__MODULE__{adapter: adapter}, texts, opts \\ []) do
    Altar.AI.batch_embed(adapter, texts, opts)
  end

  @doc """
  Classify text into one of the provided labels.

  Delegates to `Altar.AI.classify/4`.

  ## Examples

      {:ok, result} = FlowStone.AI.Resource.classify(
        resource,
        "I love this product!",
        ["positive", "negative", "neutral"]
      )
      result.label # => "positive"
      result.confidence # => 0.95
  """
  @spec classify(t(), String.t(), list(String.t()), keyword()) ::
          {:ok, Altar.AI.Classification.t()} | {:error, term()}
  def classify(%__MODULE__{adapter: adapter}, text, labels, opts \\ []) do
    Altar.AI.classify(adapter, text, labels, opts)
  end

  @doc """
  Get the capabilities of the configured adapter.

  Delegates to `Altar.AI.capabilities/1`.

  ## Examples

      capabilities = FlowStone.AI.Resource.capabilities(resource)
      capabilities.text_generation # => true
  """
  @spec capabilities(t()) :: Altar.AI.Capabilities.t()
  def capabilities(%__MODULE__{adapter: adapter}) do
    Altar.AI.capabilities(adapter)
  end

  # Private helpers

  defp get_config(key, default) do
    Application.get_env(:flowstone_ai, key, default)
  end
end
