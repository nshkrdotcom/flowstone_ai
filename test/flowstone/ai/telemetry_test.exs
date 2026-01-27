defmodule FlowStone.AI.TelemetryTest do
  # Telemetry handlers are global, so tests cannot run in parallel
  use ExUnit.Case, async: false

  alias FlowStone.AI.Telemetry

  setup do
    # Ensure clean state
    Telemetry.detach()

    on_exit(fn ->
      Telemetry.detach()
    end)

    :ok
  end

  describe "attach/0" do
    test "attaches telemetry handlers successfully" do
      assert :ok = Telemetry.attach()
    end

    test "is idempotent" do
      assert :ok = Telemetry.attach()

      # Detach and reattach should work
      assert :ok = Telemetry.detach()
      assert :ok = Telemetry.attach()
    end
  end

  describe "detach/0" do
    test "detaches telemetry handlers successfully" do
      Telemetry.attach()
      assert :ok = Telemetry.detach()
    end

    test "returns error when not attached" do
      assert {:error, :not_found} = Telemetry.detach()
    end
  end

  describe "event forwarding" do
    setup do
      Telemetry.attach()
      :ok
    end

    test "forwards LLM complete start events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-generate-start",
        [:flowstone, :ai, :generate, :start],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{system_time: 123_456_789}
      metadata = %{adapter: :test_adapter, prompt: "test prompt"}

      :telemetry.execute([:portfolio_index, :llm, :complete, :start], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-start")
    end

    test "forwards LLM complete stop events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-generate-stop",
        [:flowstone, :ai, :generate, :stop],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{duration: 1_000_000}
      metadata = %{adapter: :test_adapter}

      :telemetry.execute([:portfolio_index, :llm, :complete, :stop], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-stop")
    end

    test "forwards LLM complete exception events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-generate-exception",
        [:flowstone, :ai, :generate, :exception],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{duration: 500_000}
      metadata = %{kind: :error, reason: :timeout, stacktrace: []}

      :telemetry.execute(
        [:portfolio_index, :llm, :complete, :exception],
        measurements,
        metadata
      )

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-exception")
    end

    test "forwards embedder embed start events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-embed-start",
        [:flowstone, :ai, :embed, :start],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{system_time: 123_456_789}
      metadata = %{adapter: :test_adapter, text: "test text"}

      :telemetry.execute([:portfolio_index, :embedder, :embed, :start], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-start")
    end

    test "forwards embedder embed stop events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-embed-stop",
        [:flowstone, :ai, :embed, :stop],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{duration: 800_000}
      metadata = %{adapter: :test_adapter}

      :telemetry.execute([:portfolio_index, :embedder, :embed, :stop], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-stop")
    end

    test "forwards embedder embed exception events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-embed-exception",
        [:flowstone, :ai, :embed, :exception],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{duration: 300_000}
      metadata = %{kind: :error, reason: :network_error, stacktrace: []}

      :telemetry.execute(
        [:portfolio_index, :embedder, :embed, :exception],
        measurements,
        metadata
      )

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-exception")
    end

    test "forwards agent session execute events" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-agent-start",
        [:flowstone, :ai, :agent, :start],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:flowstone_event, measurements, metadata})
        end,
        nil
      )

      measurements = %{system_time: 123_456_789}
      metadata = %{session_id: "test_session"}

      :telemetry.execute(
        [:portfolio_index, :agent_session, :execute, :start],
        measurements,
        metadata
      )

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-agent-start")
    end

    test "preserves all metadata fields" do
      test_pid = self()

      :telemetry.attach(
        "test-metadata-preservation",
        [:flowstone, :ai, :generate, :start],
        fn _event, _measurements, metadata, _config ->
          send(test_pid, {:metadata, metadata})
        end,
        nil
      )

      metadata = %{
        adapter: :test_adapter,
        prompt: "complex prompt",
        custom_field: "custom_value",
        nested: %{data: "value"}
      }

      :telemetry.execute(
        [:portfolio_index, :llm, :complete, :start],
        %{system_time: 0},
        metadata
      )

      assert_receive {:metadata, ^metadata}, 100

      :telemetry.detach("test-metadata-preservation")
    end
  end

  describe "does not forward non-portfolio events" do
    setup do
      Telemetry.attach()
      :ok
    end

    test "ignores events from other namespaces" do
      test_pid = self()

      :telemetry.attach(
        "test-flowstone-other",
        [:flowstone, :ai, :generate, :start],
        fn _event, _measurements, _metadata, _config ->
          send(test_pid, :flowstone_event_received)
        end,
        nil
      )

      # Send event from different namespace
      :telemetry.execute([:other, :ai, :generate, :start], %{}, %{})

      refute_receive :flowstone_event_received, 50

      :telemetry.detach("test-flowstone-other")
    end
  end
end
