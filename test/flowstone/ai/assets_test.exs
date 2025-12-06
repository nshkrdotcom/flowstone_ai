defmodule FlowStone.AI.AssetsTest do
  use ExUnit.Case, async: true

  alias FlowStone.AI.{Assets, Resource}
  alias Altar.AI.Adapters.Mock

  describe "classify_each/5" do
    setup do
      call_count = :atomics.new(1, [])

      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              classify: fn _text, labels ->
                count = :atomics.add_get(call_count, 1, 1)

                label =
                  case count do
                    1 -> "positive"
                    2 -> "negative"
                    _ -> "neutral"
                  end

                confidence =
                  case count do
                    1 -> 0.95
                    2 -> 0.85
                    _ -> 0.75
                  end

                {:ok, Altar.AI.Classification.new(label, confidence, %{label => confidence})}
              end
            }
          ]
        )

      items = [
        %{id: 1, text: "I love this!"},
        %{id: 2, text: "This is terrible"},
        %{id: 3, text: "It's okay"}
      ]

      {:ok, resource: resource, items: items}
    end

    test "classifies all items successfully", %{resource: resource, items: items} do
      labels = ["positive", "negative", "neutral"]
      {:ok, results} = Assets.classify_each(resource, items, & &1.text, labels)

      assert length(results) == 3

      assert Enum.at(results, 0).classification == "positive"
      assert Enum.at(results, 0).confidence == 0.95

      assert Enum.at(results, 1).classification == "negative"
      assert Enum.at(results, 1).confidence == 0.85

      assert Enum.at(results, 2).classification == "neutral"
      assert Enum.at(results, 2).confidence == 0.75
    end

    test "preserves original item data", %{resource: resource, items: items} do
      {:ok, results} = Assets.classify_each(resource, items, & &1.text, ["positive", "negative"])

      Enum.each(results, fn result ->
        assert Map.has_key?(result, :id)
        assert Map.has_key?(result, :text)
      end)
    end

    test "accepts additional options", %{resource: resource, items: items} do
      {:ok, results} =
        Assets.classify_each(resource, items, & &1.text, ["positive", "negative"],
          temperature: 0.5
        )

      assert length(results) == 3
    end

    test "handles empty list", %{resource: resource} do
      {:ok, results} = Assets.classify_each(resource, [], & &1.text, ["label1", "label2"])

      assert results == []
    end
  end

  describe "enrich_each/4" do
    setup do
      call_count = :atomics.new(1, [])

      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              generate: fn _prompt ->
                count = :atomics.add_get(call_count, 1, 1)
                content = "Summary #{count}"
                {:ok, %Altar.AI.Response{content: content, provider: :mock, model: "mock"}}
              end
            }
          ]
        )

      items = [
        %{id: 1, content: "Article about AI"},
        %{id: 2, content: "Article about ML"},
        %{id: 3, content: "Article about DL"}
      ]

      {:ok, resource: resource, items: items}
    end

    test "enriches all items successfully", %{resource: resource, items: items} do
      {:ok, results} =
        Assets.enrich_each(resource, items, fn item ->
          "Summarize: #{item.content}"
        end)

      assert length(results) == 3

      assert Enum.at(results, 0).ai_enrichment == "Summary 1"
      assert Enum.at(results, 1).ai_enrichment == "Summary 2"
      assert Enum.at(results, 2).ai_enrichment == "Summary 3"
    end

    test "preserves original item data", %{resource: resource, items: items} do
      {:ok, results} = Assets.enrich_each(resource, items, fn _ -> "prompt" end)

      Enum.each(results, fn result ->
        assert Map.has_key?(result, :id)
        assert Map.has_key?(result, :content)
      end)
    end

    test "accepts additional options", %{resource: resource, items: items} do
      {:ok, results} =
        Assets.enrich_each(resource, items, fn _ -> "prompt" end, max_tokens: 50)

      assert length(results) == 3
    end

    test "handles empty list" do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              generate: {:ok, %Altar.AI.Response{content: "test", provider: :mock, model: "mock"}}
            }
          ]
        )

      {:ok, results} = Assets.enrich_each(resource, [], fn _ -> "prompt" end)

      assert results == []
    end

    test "handles individual enrichment failures gracefully" do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              generate: {:error, :mock_failure}
            }
          ]
        )

      items = [%{id: 1, content: "test"}]

      {:ok, results} = Assets.enrich_each(resource, items, fn _ -> "prompt" end)

      # Item should remain unchanged on error
      assert results == items
    end
  end

  describe "embed_each/4" do
    setup do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              batch_embed:
                {:ok,
                 [
                   [0.1, 0.2, 0.3],
                   [0.4, 0.5, 0.6],
                   [0.7, 0.8, 0.9]
                 ]}
            }
          ]
        )

      items = [
        %{id: 1, text: "First document"},
        %{id: 2, text: "Second document"},
        %{id: 3, text: "Third document"}
      ]

      {:ok, resource: resource, items: items}
    end

    test "embeds all items successfully", %{resource: resource, items: items} do
      {:ok, results} = Assets.embed_each(resource, items, & &1.text)

      assert length(results) == 3

      assert Enum.at(results, 0).embedding == [0.1, 0.2, 0.3]
      assert Enum.at(results, 1).embedding == [0.4, 0.5, 0.6]
      assert Enum.at(results, 2).embedding == [0.7, 0.8, 0.9]
    end

    test "preserves original item data", %{resource: resource, items: items} do
      {:ok, results} = Assets.embed_each(resource, items, & &1.text)

      Enum.each(results, fn result ->
        assert Map.has_key?(result, :id)
        assert Map.has_key?(result, :text)
      end)
    end

    test "accepts additional options", %{resource: resource, items: items} do
      {:ok, results} = Assets.embed_each(resource, items, & &1.text, model: "custom-model")

      assert length(results) == 3
    end

    test "handles empty list" do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              batch_embed: {:ok, []}
            }
          ]
        )

      {:ok, results} = Assets.embed_each(resource, [], & &1.text)

      assert results == []
    end

    test "returns error if batch embedding fails" do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              batch_embed: {:error, :mock_failure}
            }
          ]
        )

      items = [%{id: 1, text: "test"}]

      assert {:error, _} = Assets.embed_each(resource, items, & &1.text)
    end
  end

  describe "text extraction functions" do
    setup do
      {:ok, resource} =
        Resource.init(
          adapter: Mock,
          adapter_opts: [
            responses: %{
              classify: {:ok, Altar.AI.Classification.new("test", 0.9, %{"test" => 0.9})}
            }
          ]
        )

      {:ok, resource: resource}
    end

    test "works with nested data", %{resource: resource} do
      items = [
        %{user: %{comment: "nested text"}}
      ]

      {:ok, results} =
        Assets.classify_each(resource, items, fn item -> item.user.comment end, ["test"])

      assert Enum.at(results, 0).classification == "test"
    end

    test "works with different field names", %{resource: resource} do
      items = [
        %{body: "content here"}
      ]

      {:ok, results} = Assets.classify_each(resource, items, & &1.body, ["test"])

      assert Enum.at(results, 0).classification == "test"
    end
  end
end
