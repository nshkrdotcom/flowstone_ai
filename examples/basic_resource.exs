# Basic FlowStone integration usage with the Mock adapter.
#
# Run:
#   mix run examples/basic_resource.exs

alias Altar.AI.Adapters.Mock
alias Altar.AI.Integrations.FlowStone

Application.put_env(:flowstone_ai, :adapter, Mock)
Application.put_env(:flowstone_ai, :adapter_opts, [])

{:ok, resource} = FlowStone.init()

{:ok, response} = FlowStone.generate(resource, "Write a short greeting.")
IO.puts("Generate: #{response.content}")

items = [
  %{id: 1, text: "Love the new UI"},
  %{id: 2, text: "The app crashes on startup"}
]

{:ok, classified} =
  FlowStone.classify_each(resource, items, & &1.text, ["positive", "negative"])

IO.inspect(classified, label: "Classified")
