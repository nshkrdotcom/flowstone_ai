defmodule FlowStone.AI.ResourceTest do
  use ExUnit.Case, async: true

  alias FlowStone.AI.Resource
  alias FlowStone.AI.Test.ConfigurableMockEmbedder
  alias FlowStone.AI.Test.ConfigurableMockLLM
  alias FlowStone.AI.Test.MockAgentSession
  alias FlowStone.AI.Test.MockEmbedder
  alias FlowStone.AI.Test.MockLLM

  describe "setup/1" do
    test "returns resource with default adapters" do
      assert {:ok, resource} = Resource.setup(%{})
      assert resource.llm != nil
      assert resource.embedder != nil
    end

    test "accepts custom adapters" do
      assert {:ok, resource} =
               Resource.setup(%{
                 llm_adapter: MockLLM,
                 embedder_adapter: MockEmbedder
               })

      assert resource.llm == MockLLM
      assert resource.embedder == MockEmbedder
    end

    test "accepts agent session adapter" do
      assert {:ok, resource} =
               Resource.setup(%{
                 llm_adapter: MockLLM,
                 embedder_adapter: MockEmbedder,
                 agent_session_adapter: MockAgentSession
               })

      assert resource.agent_session == MockAgentSession
    end

    test "agent_session is nil when not configured" do
      assert {:ok, resource} =
               Resource.setup(%{
                 llm_adapter: MockLLM,
                 embedder_adapter: MockEmbedder
               })

      assert resource.agent_session == nil
    end

    test "passes through extra options" do
      assert {:ok, resource} =
               Resource.setup(%{
                 llm_adapter: MockLLM,
                 embedder_adapter: MockEmbedder,
                 temperature: 0.5
               })

      assert {:temperature, 0.5} in resource.opts
    end
  end

  describe "generate/3" do
    setup do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder
        })

      {:ok, resource: resource}
    end

    test "generates text successfully", %{resource: resource} do
      {:ok, response} = Resource.generate(resource, "test prompt")

      assert response.content == "mock response"
      assert response.model == "mock-model"
      assert is_map(response.usage)
      assert is_map(response.metadata)
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, response} = Resource.generate(resource, "test prompt", max_tokens: 100)

      assert response.content == "mock response"
    end

    test "returns error on adapter failure" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: ConfigurableMockLLM,
          embedder_adapter: MockEmbedder
        })

      Process.put(:mock_llm_response, {:error, :mock_failure})
      assert {:error, :mock_failure} = Resource.generate(resource, "test")
    after
      Process.delete(:mock_llm_response)
    end
  end

  describe "embed/3" do
    setup do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder
        })

      {:ok, resource: resource}
    end

    test "generates embeddings successfully", %{resource: resource} do
      {:ok, vector} = Resource.embed(resource, "test text")

      assert vector == [0.1, 0.2, 0.3]
      assert is_list(vector)
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, vector} = Resource.embed(resource, "test text", model: "custom-model")

      assert is_list(vector)
    end

    test "returns error on adapter failure" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: ConfigurableMockEmbedder
        })

      Process.put(:mock_embedder_response, {:error, :embed_failure})
      assert {:error, :embed_failure} = Resource.embed(resource, "test")
    after
      Process.delete(:mock_embedder_response)
    end
  end

  describe "batch_embed/3" do
    setup do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder
        })

      {:ok, resource: resource}
    end

    test "generates batch embeddings successfully", %{resource: resource} do
      texts = ["text1", "text2", "text3"]
      {:ok, vectors} = Resource.batch_embed(resource, texts)

      assert length(vectors) == 3
      assert Enum.all?(vectors, &is_list/1)
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, vectors} = Resource.batch_embed(resource, ["text1"], model: "custom-model")

      assert is_list(vectors)
    end

    test "returns error on adapter failure" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: ConfigurableMockEmbedder
        })

      Process.put(:mock_embedder_batch_response, {:error, :batch_failure})
      assert {:error, :batch_failure} = Resource.batch_embed(resource, ["test"])
    after
      Process.delete(:mock_embedder_batch_response)
    end
  end

  describe "classify/4" do
    test "classifies text successfully" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: ConfigurableMockLLM,
          embedder_adapter: MockEmbedder
        })

      Process.put(:mock_llm_response, fn _messages, _opts ->
        {:ok,
         %{
           content: "positive",
           model: "mock-model",
           usage: %{input_tokens: 10, output_tokens: 5},
           finish_reason: :stop
         }}
      end)

      labels = ["positive", "negative", "neutral"]
      {:ok, result} = Resource.classify(resource, "I love this!", labels)

      assert result.label == "positive"
      assert result.confidence == 1.0
      assert is_map(result.scores)
    after
      Process.delete(:mock_llm_response)
    end

    test "falls back to first label when response doesn't match" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: ConfigurableMockLLM,
          embedder_adapter: MockEmbedder
        })

      Process.put(:mock_llm_response, fn _messages, _opts ->
        {:ok,
         %{
           content: "unknown_label",
           model: "mock-model",
           usage: %{input_tokens: 10, output_tokens: 5},
           finish_reason: :stop
         }}
      end)

      labels = ["positive", "negative"]
      {:ok, result} = Resource.classify(resource, "test text", labels)

      assert result.label == "positive"
      assert result.confidence == 0.0
    after
      Process.delete(:mock_llm_response)
    end

    test "returns error on adapter failure" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: ConfigurableMockLLM,
          embedder_adapter: MockEmbedder
        })

      Process.put(:mock_llm_response, {:error, :classify_failure})
      assert {:error, :classify_failure} = Resource.classify(resource, "test", ["a", "b"])
    after
      Process.delete(:mock_llm_response)
    end
  end

  describe "capabilities/1" do
    test "returns adapter capabilities without agent session" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder
        })

      capabilities = Resource.capabilities(resource)

      assert capabilities.generate == true
      assert capabilities.embed == true
      assert capabilities.classify == true
      assert capabilities.batch_embed == true
      assert capabilities.stream == true
      assert capabilities.agent_session == false
    end

    test "returns agent_session: true when configured" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder,
          agent_session_adapter: MockAgentSession
        })

      capabilities = Resource.capabilities(resource)

      assert capabilities.agent_session == true
    end
  end

  describe "FlowStone.Resource behaviour" do
    test "teardown returns :ok" do
      {:ok, resource} =
        Resource.setup(%{llm_adapter: MockLLM, embedder_adapter: MockEmbedder})

      assert :ok = Resource.teardown(resource)
    end

    test "health_check returns :healthy" do
      {:ok, resource} =
        Resource.setup(%{llm_adapter: MockLLM, embedder_adapter: MockEmbedder})

      assert :healthy = Resource.health_check(resource)
    end
  end

  describe "agent session support" do
    test "start_agent_session/3 delegates to adapter" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder,
          agent_session_adapter: MockAgentSession
        })

      assert {:ok, session_id} = Resource.start_agent_session(resource, "test_agent", [])
      assert is_binary(session_id)
    end

    test "start_agent_session/3 returns error when not configured" do
      {:ok, resource} =
        Resource.setup(%{llm_adapter: MockLLM, embedder_adapter: MockEmbedder})

      assert {:error, :agent_session_not_configured} =
               Resource.start_agent_session(resource, "test_agent", [])
    end

    test "execute_agent/4 delegates to adapter" do
      {:ok, resource} =
        Resource.setup(%{
          llm_adapter: MockLLM,
          embedder_adapter: MockEmbedder,
          agent_session_adapter: MockAgentSession
        })

      {:ok, session_id} = Resource.start_agent_session(resource, "test_agent", [])

      assert {:ok, result} =
               Resource.execute_agent(resource, session_id, %{prompt: "test"}, [])

      assert result.output == "mock agent output"
      assert result.turn_count == 1
    end

    test "execute_agent/4 returns error when not configured" do
      {:ok, resource} =
        Resource.setup(%{llm_adapter: MockLLM, embedder_adapter: MockEmbedder})

      assert {:error, :agent_session_not_configured} =
               Resource.execute_agent(resource, "session", %{}, [])
    end
  end

  describe "configuration" do
    test "uses application config for llm_adapter" do
      original = Application.get_env(:flowstone_ai, :llm_adapter)

      try do
        Application.put_env(:flowstone_ai, :llm_adapter, MockLLM)
        {:ok, resource} = Resource.setup(%{embedder_adapter: MockEmbedder})

        assert resource.llm == MockLLM
      after
        if original do
          Application.put_env(:flowstone_ai, :llm_adapter, original)
        else
          Application.delete_env(:flowstone_ai, :llm_adapter)
        end
      end
    end

    test "uses application config for embedder_adapter" do
      original = Application.get_env(:flowstone_ai, :embedder_adapter)

      try do
        Application.put_env(:flowstone_ai, :embedder_adapter, MockEmbedder)
        {:ok, resource} = Resource.setup(%{llm_adapter: MockLLM})

        assert resource.embedder == MockEmbedder
      after
        if original do
          Application.put_env(:flowstone_ai, :embedder_adapter, original)
        else
          Application.delete_env(:flowstone_ai, :embedder_adapter)
        end
      end
    end
  end
end
