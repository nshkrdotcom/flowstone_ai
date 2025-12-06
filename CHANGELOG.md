# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-15

### Added

- Initial release of FlowStone.AI
- `FlowStone.AI.Resource` - FlowStone Resource behaviour for AI capabilities
  - `setup/1` callback integration
  - `generate/3` - Text generation
  - `classify/4` - Text classification
  - `embed/3` - Single text embedding
  - `batch_embed/3` - Batch embedding
  - `capabilities/1` - Query adapter capabilities
  - `health_check/1` - Resource health monitoring
- `FlowStone.AI.Assets` - DSL helpers for common AI patterns
  - `classify_each/5` - Batch classification with automatic mapping
  - `enrich_each/4` - Batch enrichment via AI generation
  - `embed_each/4` - Batch embedding generation
- `FlowStone.AI.Telemetry` - Telemetry bridge from altar_ai to FlowStone
  - Forwards `[:altar, :ai, ...]` events to `[:flowstone, :ai, ...]`
- Configuration via `:flowstone_ai` application environment
- Comprehensive test suite

### Features

- Unified AI access via FlowStone Resource pattern
- DSL helpers for common pipeline patterns
- Automatic provider fallback via altar_ai Composite adapter
- Telemetry integration for observability
- Graceful degradation when AI unavailable

[0.1.0]: https://github.com/nshkrdotcom/flowstone_ai/releases/tag/v0.1.0
