defmodule FlowStone.AI.ResourceTest do
  use ExUnit.Case, async: true

  alias Altar.AI.Adapters.Mock
  alias Altar.AI.Classification
  alias Altar.AI.Integrations.FlowStone, as: Integration
  alias Altar.AI.Response
  alias FlowStone.AI.Resource

  describe "init/1" do
    test "initializes with default Composite adapter" do
      {:ok, resource} = Resource.legacy_init()

      assert %Integration{} = resource
      assert resource.adapter != nil
    end

    test "initializes with custom adapter" do
      {:ok, resource} = Resource.legacy_init(adapter: Mock, adapter_opts: [])

      assert %Integration{} = resource
      assert match?(%Mock{}, resource.adapter)
    end

    test "initializes with adapter options" do
      opts = [responses: ["test response"]]
      {:ok, resource} = Resource.legacy_init(adapter: Mock, adapter_opts: opts)

      assert %Integration{} = resource
      assert match?(%Mock{}, resource.adapter)
    end
  end

  describe "generate/3" do
    setup do
      {:ok, resource} =
        Resource.legacy_init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              generate:
                {:ok, %Response{content: "Generated response", provider: :mock, model: "mock"}}
            }
          ]
        )

      {:ok, resource: resource}
    end

    test "generates text successfully", %{resource: resource} do
      {:ok, response} = Resource.legacy_generate(resource, "test prompt")

      assert response.content == "Generated response"
      assert is_map(response.metadata)
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, response} = Resource.legacy_generate(resource, "test prompt", max_tokens: 100)

      assert response.content == "Generated response"
    end
  end

  describe "embed/3" do
    setup do
      {:ok, resource} =
        Resource.legacy_init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              embed: {:ok, [0.1, 0.2, 0.3]}
            }
          ]
        )

      {:ok, resource: resource}
    end

    test "generates embeddings successfully", %{resource: resource} do
      {:ok, vector} = Resource.legacy_embed(resource, "test text")

      assert vector == [0.1, 0.2, 0.3]
      assert is_list(vector)
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, vector} = Resource.legacy_embed(resource, "test text", model: "custom-model")

      assert is_list(vector)
    end
  end

  describe "batch_embed/3" do
    setup do
      {:ok, resource} =
        Resource.legacy_init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              batch_embed: {:ok, [[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]]}
            }
          ]
        )

      {:ok, resource: resource}
    end

    test "generates batch embeddings successfully", %{resource: resource} do
      texts = ["text1", "text2", "text3"]
      {:ok, vectors} = Resource.legacy_batch_embed(resource, texts)

      assert length(vectors) == 3
      assert vectors == [[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]]
    end

    test "accepts additional options", %{resource: resource} do
      {:ok, vectors} = Resource.legacy_batch_embed(resource, ["text1"], model: "custom-model")

      assert is_list(vectors)
    end
  end

  describe "classify/4" do
    setup do
      {:ok, resource} =
        Resource.legacy_init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              classify: {:ok, Classification.new("positive", 0.95, %{"positive" => 0.95})}
            }
          ]
        )

      {:ok, resource: resource}
    end

    test "classifies text successfully", %{resource: resource} do
      labels = ["positive", "negative", "neutral"]
      {:ok, result} = Resource.legacy_classify(resource, "I love this!", labels)

      assert result.label == "positive"
      assert result.confidence == 0.95
    end

    test "accepts additional options", %{resource: resource} do
      labels = ["positive", "negative"]
      {:ok, result} = Resource.legacy_classify(resource, "test text", labels, temperature: 0.5)

      assert is_binary(result.label)
      assert is_float(result.confidence)
    end
  end

  describe "capabilities/1" do
    setup do
      {:ok, resource} = Resource.legacy_init(adapter: Mock)
      {:ok, resource: resource}
    end

    test "returns adapter capabilities", %{resource: resource} do
      capabilities = Resource.legacy_capabilities(resource)

      assert capabilities.generate == true
      assert capabilities.embed == true
      assert capabilities.classify == true
    end
  end

  describe "configuration" do
    test "uses application config for adapter" do
      original = Application.get_env(:flowstone_ai, :adapter)

      try do
        Application.put_env(:flowstone_ai, :adapter, Mock)
        {:ok, resource} = Resource.legacy_init()

        assert match?(%Mock{}, resource.adapter)
      after
        if original do
          Application.put_env(:flowstone_ai, :adapter, original)
        else
          Application.delete_env(:flowstone_ai, :adapter)
        end
      end
    end

    test "uses application config for adapter_opts" do
      original = Application.get_env(:flowstone_ai, :adapter_opts)

      try do
        test_opts = [
          responses: %{
            generate:
              {:ok,
               %Altar.AI.Response{content: "config response", provider: :mock, model: "mock"}}
          }
        ]

        Application.put_env(:flowstone_ai, :adapter, Mock)
        Application.put_env(:flowstone_ai, :adapter_opts, test_opts)

        {:ok, resource} = Resource.legacy_init()
        {:ok, response} = Resource.legacy_generate(resource, "test")

        assert response.content == "config response"
      after
        if original do
          Application.put_env(:flowstone_ai, :adapter_opts, original)
        else
          Application.delete_env(:flowstone_ai, :adapter_opts)
        end

        Application.delete_env(:flowstone_ai, :adapter)
      end
    end
  end
end
