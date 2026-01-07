# FlowStone.AI

<div align="center">
  <img src="assets/flowstone_ai.svg" alt="FlowStone.AI Logo" width="200"/>
  <br/>
  <br/>

  [![Hex.pm](https://img.shields.io/hexpm/v/flowstone_ai.svg)](https://hex.pm/packages/flowstone_ai)
  [![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/flowstone_ai)
  [![License](https://img.shields.io/hexpm/l/flowstone_ai.svg)](LICENSE)
</div>

FlowStone integration for [altar_ai](https://github.com/nshkrdotcom/altar_ai) - AI-powered data pipeline assets with automatic provider fallback and unified telemetry.

> **Deprecation Notice**: `flowstone_ai` is deprecated in favor of using
> `Altar.AI.Integrations.FlowStone` directly from the `altar_ai` package. This
> package remains as a thin compatibility layer.

## What is FlowStone.AI?

**FlowStone.AI** is a thin integration layer that brings the power of `altar_ai` into FlowStone's resource system. It enables you to build AI-powered data pipelines with:

- **Unified AI Interface**: Use any AI provider (Gemini, Claude, OpenAI, etc.) through altar_ai's adapter system
- **Automatic Fallback**: Built-in provider failover when using the Composite adapter
- **FlowStone Resources**: AI capabilities exposed as native FlowStone resources
- **Helper Functions**: Common patterns (classify, enrich, embed) as ready-to-use helpers
- **Unified Telemetry**: All AI operations integrated into FlowStone's telemetry system

## Architecture

```
flowstone_ai (thin integration layer)
    |
    +-- FlowStone.AI.Resource (FlowStone Resource implementation)
    |       |
    |       +-- delegates to altar_ai
    |
    +-- FlowStone.AI.Assets (DSL helpers for common patterns)
    |
    +-- FlowStone.AI.Telemetry (telemetry bridge)

altar_ai (AI abstraction layer)
    |
    +-- Adapters: Gemini, Claude, OpenAI, Ollama, Composite
    +-- Protocols: generate, embed, classify
    +-- Telemetry: [:altar, :ai, ...] events

flowstone (data pipeline framework)
    |
    +-- Resources: External system integrations
    +-- Assets: Pipeline definitions
    +-- Telemetry: [:flowstone, ...] events
```

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:flowstone_ai, path: "../flowstone_ai"},
    # Or from Hex:
    # {:flowstone_ai, "~> 0.1.0"}
  ]
end
```

## Configuration

### Basic Configuration

```elixir
# config/config.exs
config :flowstone_ai,
  adapter: Altar.AI.Adapters.Gemini,
  adapter_opts: [
    api_key: System.get_env("GEMINI_API_KEY")
  ]
```

### Using the Composite Adapter (Recommended)

The Composite adapter provides automatic fallback across multiple providers:

```elixir
config :flowstone_ai,
  adapter: Altar.AI.Adapters.Composite,
  adapter_opts: [
    adapters: [
      {Altar.AI.Adapters.Gemini, [api_key: System.get_env("GEMINI_API_KEY")]},
      {Altar.AI.Adapters.Claude, [api_key: System.get_env("CLAUDE_API_KEY")]},
      {Altar.AI.Adapters.OpenAI, [api_key: System.get_env("OPENAI_API_KEY")]}
    ]
  ]
```

## Usage

### 1. Register the AI Resource

In your application startup or pipeline definition:

```elixir
FlowStone.Resources.register(:ai, FlowStone.AI.Resource, [])
```

### 2. Set Up Telemetry (Optional)

To bridge altar_ai events to FlowStone's telemetry namespace:

```elixir
def start(_type, _args) do
  FlowStone.AI.setup_telemetry()
  # ... rest of startup
end
```

### 3. Use in Assets

#### Text Generation

```elixir
asset :summarized_articles do
  depends_on [:raw_articles]
  requires [:ai]

  execute fn ctx, %{raw_articles: articles} ->
    summaries = Enum.map(articles, fn article ->
      {:ok, response} = FlowStone.AI.Resource.generate(
        ctx.resources.ai,
        "Summarize this article in 2 sentences: #{article.body}"
      )

      Map.put(article, :summary, response.content)
    end)

    {:ok, summaries}
  end
end
```

## Examples

Run `examples/basic_resource.exs` to exercise the resource and helper
functions with the Mock adapter.

#### Classification (with Helper)

```elixir
asset :classified_feedback do
  depends_on [:user_feedback]
  requires [:ai]

  execute fn ctx, %{user_feedback: feedback} ->
    FlowStone.AI.Assets.classify_each(
      ctx.resources.ai,
      feedback,
      & &1.comment,
      ["bug", "feature_request", "question", "praise"]
    )
  end
end
```

#### Embeddings for Search

```elixir
asset :searchable_documents do
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
```

#### Content Enrichment

```elixir
asset :enriched_products do
  depends_on [:products]
  requires [:ai]

  execute fn ctx, %{products: products} ->
    FlowStone.AI.Assets.enrich_each(
      ctx.resources.ai,
      products,
      fn product ->
        "Write a catchy tagline for: #{product.name} - #{product.description}"
      end
    )
  end
end
```

## API Reference

### FlowStone.AI.Resource

The core resource implementation that delegates to altar_ai.

```elixir
# Initialize
{:ok, resource} = FlowStone.AI.Resource.init()

# Generate text
{:ok, response} = FlowStone.AI.Resource.generate(resource, "prompt")
response.content # => "generated text"

# Generate embeddings
{:ok, vector} = FlowStone.AI.Resource.embed(resource, "text to embed")
length(vector) # => 768 (or adapter-specific dimension)

# Batch embeddings
{:ok, vectors} = FlowStone.AI.Resource.batch_embed(resource, ["text1", "text2"])

# Classification
{:ok, result} = FlowStone.AI.Resource.classify(
  resource,
  "I love this!",
  ["positive", "negative", "neutral"]
)
result.label # => "positive"
result.confidence # => 0.95

# Check capabilities
capabilities = FlowStone.AI.Resource.capabilities(resource)
capabilities.text_generation # => true
```

### FlowStone.AI.Assets

Helper functions for common AI patterns in assets.

```elixir
# Classify each item in a collection
{:ok, classified} = FlowStone.AI.Assets.classify_each(
  resource,
  items,
  &(&1.text),
  ["label1", "label2"]
)

# Enrich each item with AI-generated content
{:ok, enriched} = FlowStone.AI.Assets.enrich_each(
  resource,
  items,
  fn item -> "prompt for #{item.field}" end
)

# Generate embeddings for each item
{:ok, embedded} = FlowStone.AI.Assets.embed_each(
  resource,
  items,
  &(&1.content)
)
```

### FlowStone.AI.Telemetry

Bridges altar_ai telemetry to FlowStone's namespace.

```elixir
# Attach handlers (idempotent)
FlowStone.AI.Telemetry.attach()

# Detach handlers
FlowStone.AI.Telemetry.detach()
```

**Events forwarded:**

- `[:altar, :ai, :generate, :start]` -> `[:flowstone, :ai, :generate, :start]`
- `[:altar, :ai, :generate, :stop]` -> `[:flowstone, :ai, :generate, :stop]`
- `[:altar, :ai, :generate, :exception]` -> `[:flowstone, :ai, :generate, :exception]`
- `[:altar, :ai, :embed, :start]` -> `[:flowstone, :ai, :embed, :start]`
- `[:altar, :ai, :embed, :stop]` -> `[:flowstone, :ai, :embed, :stop]`
- `[:altar, :ai, :embed, :exception]` -> `[:flowstone, :ai, :embed, :exception]`

## Complete Example: AI-Powered Feedback Pipeline

```elixir
defmodule MyApp.FeedbackPipeline do
  use FlowStone.Pipeline

  # Register AI resource
  resource :ai, FlowStone.AI.Resource, []

  # Ingest raw feedback
  asset :raw_feedback do
    execute fn _ctx, _deps ->
      feedback = fetch_feedback_from_db()
      {:ok, feedback}
    end
  end

  # Classify sentiment
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

  # Generate embeddings for similarity search
  asset :searchable_feedback do
    depends_on [:classified_feedback]
    requires [:ai]

    execute fn ctx, %{classified_feedback: feedback} ->
      FlowStone.AI.Assets.embed_each(
        ctx.resources.ai,
        feedback,
        & &1.text
      )
    end
  end

  # Enrich negative feedback with suggested responses
  asset :enriched_negative_feedback do
    depends_on [:classified_feedback]
    requires [:ai]

    execute fn ctx, %{classified_feedback: feedback} ->
      negative = Enum.filter(feedback, & &1.classification == "negative")

      FlowStone.AI.Assets.enrich_each(
        ctx.resources.ai,
        negative,
        fn item ->
          "Write a professional, empathetic response to this feedback: #{item.text}"
        end
      )
    end
  end
end
```

## Error Handling

FlowStone.AI propagates errors from altar_ai and the underlying adapters:

```elixir
case FlowStone.AI.Resource.generate(resource, prompt) do
  {:ok, response} ->
    # Success
    IO.puts(response.content)

  {:error, %{reason: :rate_limit, retry_after: seconds}} ->
    # Handle rate limiting
    :timer.sleep(seconds * 1000)

  {:error, %{reason: :timeout}} ->
    # Handle timeout
    Logger.warn("AI request timed out")

  {:error, reason} ->
    # Handle other errors
    Logger.error("AI request failed: #{inspect(reason)}")
end
```

When using the Composite adapter, it will automatically try the next provider on failure.

## Testing

FlowStone.AI tests use the `Altar.AI.Adapters.Mock` adapter for deterministic testing:

```elixir
defmodule MyApp.PipelineTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, resource} = FlowStone.AI.Resource.init(
      adapter: Altar.AI.Adapters.Mock,
      adapter_opts: [
        responses: ["test response"],
        classifications: [%{label: "positive", confidence: 0.9}]
      ]
    )

    {:ok, resource: resource}
  end

  test "generates text", %{resource: resource} do
    {:ok, response} = FlowStone.AI.Resource.generate(resource, "test")
    assert response.content == "test response"
  end
end
```

## Performance Considerations

- **Batch Operations**: Use `batch_embed/3` instead of multiple `embed/2` calls for better performance
- **Caching**: Consider caching embeddings and expensive generations
- **Rate Limiting**: The Composite adapter handles rate limits automatically with exponential backoff
- **Async Assets**: FlowStone assets can run concurrently when dependencies allow

## Dependencies

- **altar_ai** - Required: AI abstraction layer with multi-provider support
- **flowstone** - Required: Data pipeline framework
- **supertester** - Test only: Enhanced testing utilities

## License

MIT License - See [LICENSE](LICENSE) for details

## Links

- **GitHub**: https://github.com/nshkrdotcom/flowstone_ai
- **altar_ai**: https://github.com/nshkrdotcom/altar_ai
- **FlowStone**: https://github.com/nshkrdotcom/flowstone
- **Documentation**: https://hexdocs.pm/flowstone_ai

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`mix test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Support

- Open an issue on [GitHub](https://github.com/nshkrdotcom/flowstone_ai/issues)
- Check the [documentation](https://hexdocs.pm/flowstone_ai)
