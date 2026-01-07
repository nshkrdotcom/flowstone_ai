defmodule FlowStone.AI.TelemetryTest do
  # Telemetry handlers are global, so tests cannot run in parallel
  use ExUnit.Case, async: false

  alias FlowStone.AI.Telemetry

  setup do
    # Ensure clean state
    Telemetry.legacy_detach()

    on_exit(fn ->
      Telemetry.legacy_detach()
    end)

    :ok
  end

  describe "attach/0" do
    test "attaches telemetry handlers successfully" do
      assert :ok = Telemetry.legacy_attach()
    end

    test "is idempotent" do
      assert :ok = Telemetry.legacy_attach()

      # Detach and reattach should work
      assert :ok = Telemetry.legacy_detach()
      assert :ok = Telemetry.legacy_attach()
    end
  end

  describe "detach/0" do
    test "detaches telemetry handlers successfully" do
      Telemetry.legacy_attach()
      assert :ok = Telemetry.legacy_detach()
    end

    test "returns error when not attached" do
      assert {:error, :not_found} = Telemetry.legacy_detach()
    end
  end

  describe "event forwarding" do
    setup do
      Telemetry.legacy_attach()
      :ok
    end

    test "forwards generate start events" do
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

      :telemetry.execute([:altar, :ai, :generate, :start], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-start")
    end

    test "forwards generate stop events" do
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

      :telemetry.execute([:altar, :ai, :generate, :stop], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-stop")
    end

    test "forwards generate exception events" do
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

      :telemetry.execute([:altar, :ai, :generate, :exception], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-generate-exception")
    end

    test "forwards embed start events" do
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

      :telemetry.execute([:altar, :ai, :embed, :start], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-start")
    end

    test "forwards embed stop events" do
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

      :telemetry.execute([:altar, :ai, :embed, :stop], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-stop")
    end

    test "forwards embed exception events" do
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

      :telemetry.execute([:altar, :ai, :embed, :exception], measurements, metadata)

      assert_receive {:flowstone_event, ^measurements, ^metadata}, 100

      :telemetry.detach("test-flowstone-embed-exception")
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

      :telemetry.execute([:altar, :ai, :generate, :start], %{system_time: 0}, metadata)

      assert_receive {:metadata, ^metadata}, 100

      :telemetry.detach("test-metadata-preservation")
    end
  end

  describe "does not forward non-altar events" do
    setup do
      Telemetry.legacy_attach()
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
