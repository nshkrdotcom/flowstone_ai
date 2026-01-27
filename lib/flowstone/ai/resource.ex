defmodule FlowStone.AI.Resource do
  @moduledoc """
  FlowStone Resource that provides AI capabilities to assets.

  Delegates to portfolio_core/portfolio_index for LLM, Embedder, and
  AgentSession support, giving FlowStone access to all portfolio providers
  with rate limiting, telemetry, and agent session capabilities.

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
        llm_adapter: PortfolioIndex.Adapters.LLM.Gemini,
        embedder_adapter: PortfolioIndex.Adapters.Embedder.Gemini,
        agent_session_adapter: PortfolioIndex.Adapters.AgentSession.Claude

  The resource will use the configured adapters, defaulting to Gemini for LLM
  and Embedder if not specified.
  """

  @behaviour FlowStone.Resource

  @type t :: %__MODULE__{
          llm: module(),
          embedder: module(),
          agent_session: module() | nil,
          opts: keyword()
        }

  defstruct [:llm, :embedder, :agent_session, opts: []]

  @default_llm PortfolioIndex.Adapters.LLM.Gemini
  @default_embedder PortfolioIndex.Adapters.Embedder.Gemini

  @impl true
  @doc """
  Set up the AI resource.

  Resolves LLM, Embedder, and optional AgentSession adapters from config
  or defaults.

  ## Options

    * `:llm_adapter` - Module implementing `PortfolioCore.Ports.LLM`
    * `:embedder_adapter` - Module implementing `PortfolioCore.Ports.Embedder`
    * `:agent_session_adapter` - Module implementing `PortfolioCore.Ports.AgentSession`
    * Additional options are passed through to adapter calls

  """
  @spec setup(map()) :: {:ok, t()} | {:error, term()}
  def setup(config) when is_map(config) do
    llm =
      Map.get(config, :llm_adapter) ||
        Application.get_env(:flowstone_ai, :llm_adapter, @default_llm)

    embedder =
      Map.get(config, :embedder_adapter) ||
        Application.get_env(:flowstone_ai, :embedder_adapter, @default_embedder)

    agent_session =
      Map.get(config, :agent_session_adapter) ||
        Application.get_env(:flowstone_ai, :agent_session_adapter)

    opts =
      config
      |> Map.drop([:llm_adapter, :embedder_adapter, :agent_session_adapter])
      |> Map.to_list()

    {:ok,
     %__MODULE__{
       llm: llm,
       embedder: embedder,
       agent_session: agent_session,
       opts: opts
     }}
  end

  @impl true
  @doc """
  Teardown the AI resource. Returns `:ok`.
  """
  @spec teardown(t()) :: :ok
  def teardown(_resource), do: :ok

  @impl true
  @doc """
  Check the health of the AI resource.
  """
  @spec health_check(t()) :: :healthy | {:unhealthy, term()}
  def health_check(_resource), do: :healthy

  @doc """
  Generate text using the configured LLM adapter.

  Calls `adapter.complete/2` with the prompt wrapped as a user message,
  and normalizes the response.

  ## Parameters

    * `resource` - The AI resource
    * `prompt` - The text prompt
    * `opts` - Additional options passed to `complete/2`

  ## Returns

    * `{:ok, result}` - With `:content`, `:model`, `:usage`, `:finish_reason`
    * `{:error, reason}` - On failure

  """
  @spec generate(t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def generate(%__MODULE__{} = resource, prompt, opts \\ []) do
    messages = [%{role: :user, content: prompt}]
    merged_opts = Keyword.merge(resource.opts, opts)

    :telemetry.execute(
      [:flowstone, :ai, :generate, :start],
      %{system_time: System.system_time()},
      %{adapter: resource.llm, prompt: prompt}
    )

    start_time = System.monotonic_time()

    case resource.llm.complete(messages, merged_opts) do
      {:ok, result} ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:flowstone, :ai, :generate, :stop],
          %{duration: duration},
          %{adapter: resource.llm, model: result.model}
        )

        {:ok, normalize_llm_result(result)}

      {:error, reason} = error ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:flowstone, :ai, :generate, :exception],
          %{duration: duration},
          %{adapter: resource.llm, kind: :error, reason: reason, stacktrace: []}
        )

        error
    end
  end

  @doc """
  Generate an embedding for a single text.

  Calls `adapter.embed/2` and normalizes the response.

  ## Returns

    * `{:ok, vector}` - List of floats
    * `{:error, reason}` - On failure

  """
  @spec embed(t(), String.t(), keyword()) :: {:ok, [float()]} | {:error, term()}
  def embed(%__MODULE__{} = resource, text, opts \\ []) do
    merged_opts = Keyword.merge(resource.opts, opts)

    :telemetry.execute(
      [:flowstone, :ai, :embed, :start],
      %{system_time: System.system_time()},
      %{adapter: resource.embedder, text: text}
    )

    start_time = System.monotonic_time()

    case resource.embedder.embed(text, merged_opts) do
      {:ok, %{vector: vector}} ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:flowstone, :ai, :embed, :stop],
          %{duration: duration},
          %{adapter: resource.embedder}
        )

        {:ok, vector}

      {:error, reason} = error ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:flowstone, :ai, :embed, :exception],
          %{duration: duration},
          %{adapter: resource.embedder, kind: :error, reason: reason, stacktrace: []}
        )

        error
    end
  end

  @doc """
  Generate embeddings for multiple texts in batch.

  Calls `adapter.embed_batch/2` and returns the vectors.

  ## Returns

    * `{:ok, vectors}` - List of embedding vectors
    * `{:error, reason}` - On failure

  """
  @spec batch_embed(t(), [String.t()], keyword()) :: {:ok, [[float()]]} | {:error, term()}
  def batch_embed(%__MODULE__{} = resource, texts, opts \\ []) do
    merged_opts = Keyword.merge(resource.opts, opts)

    case resource.embedder.embed_batch(texts, merged_opts) do
      {:ok, %{embeddings: embeddings}} ->
        vectors = Enum.map(embeddings, & &1.vector)
        {:ok, vectors}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Classify text into one of the provided labels using the LLM.

  Builds a classification prompt and parses the LLM response.

  ## Returns

    * `{:ok, result}` - With `:label`, `:confidence`, `:scores`
    * `{:error, reason}` - On failure

  """
  @spec classify(t(), String.t(), [String.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def classify(%__MODULE__{} = resource, text, labels, opts \\ []) do
    prompt = build_classification_prompt(text, labels)
    messages = [%{role: :user, content: prompt}]
    merged_opts = Keyword.merge(resource.opts, opts)

    case resource.llm.complete(messages, merged_opts) do
      {:ok, result} ->
        label = parse_classification_label(result.content, labels)
        confidence = if label, do: 1.0, else: 0.0

        scores =
          labels
          |> Enum.map(fn l ->
            {l, if(l == label, do: 1.0, else: 0.0)}
          end)
          |> Map.new()

        {:ok, %{label: label || List.first(labels), confidence: confidence, scores: scores}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get the capabilities of the configured adapters.

  Returns a map indicating which capabilities are available.
  """
  @spec capabilities(t()) :: map()
  def capabilities(%__MODULE__{} = resource) do
    %{
      generate: true,
      embed: true,
      classify: true,
      batch_embed: true,
      stream: true,
      agent_session: resource.agent_session != nil
    }
  end

  @doc """
  Start an agent session using the configured AgentSession adapter.

  ## Parameters

    * `resource` - The AI resource
    * `agent_id` - Identifier for the agent type/configuration
    * `opts` - Session options

  ## Returns

    * `{:ok, session_id}` - Session started successfully
    * `{:error, reason}` - On failure

  """
  @spec start_agent_session(t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def start_agent_session(%__MODULE__{agent_session: nil}, _agent_id, _opts) do
    {:error, :agent_session_not_configured}
  end

  def start_agent_session(%__MODULE__{} = resource, agent_id, opts) do
    resource.agent_session.start_session(agent_id, opts)
  end

  @doc """
  Execute within an agent session.

  ## Parameters

    * `resource` - The AI resource
    * `session_id` - The session to execute within
    * `input` - Input data for the run
    * `opts` - Execution options

  ## Returns

    * `{:ok, run_result}` - Run completed
    * `{:error, reason}` - On failure

  """
  @spec execute_agent(t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def execute_agent(%__MODULE__{agent_session: nil}, _session_id, _input, _opts) do
    {:error, :agent_session_not_configured}
  end

  def execute_agent(%__MODULE__{} = resource, session_id, input, opts) do
    resource.agent_session.execute(session_id, input, opts)
  end

  # ---- Private ----

  defp normalize_llm_result(result) do
    %{
      content: result.content,
      model: result.model,
      usage: result.usage,
      finish_reason: result.finish_reason,
      metadata: %{}
    }
  end

  defp build_classification_prompt(text, labels) do
    labels_str = Enum.join(labels, ", ")

    """
    Classify the following text into exactly one of these labels: #{labels_str}

    Text: #{text}

    Respond with only the label, nothing else.
    """
  end

  defp parse_classification_label(content, labels) do
    normalized = content |> String.trim() |> String.downcase()

    Enum.find(labels, fn label ->
      String.downcase(label) == normalized
    end)
  end
end
