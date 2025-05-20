defmodule NaughtyList.Cli do
  def main(args) do
    case args do
      ["list-subgraphs"] -> find_pinned_subgraphs()
      [] -> print_help()
      ["help"] -> print_help()
      args -> calculate_naughties(args)
    end
  end

  def print_help do
    IO.puts("""
    naughty_list help menu:

    list-subgraphs: Tries to find all subgraphs pinned to IPFS (might take a while, it's slow)
    help: prints this menu
    "Qm.... Qm....": Calculates the naughty list of subgraphs that use eth-calls
    """)
  end

  def find_pinned_subgraphs do
    # "https://ipfs.network.thegraph.com/ipfs/api/v0/pin/ls?size=true&stream=true"
    conn = Ipfs.conn()
    Ipfs.list_pinned(conn) |> IO.inspect()
  end

  def calculate_naughties(args) do
    conn = Ipfs.conn()

    count = Enum.count(args)

    result =
      EthCalls.sg_find_handles(args)
      |> Enum.map(fn {deployment_id, files} ->
        has_eth_calls =
          Enum.any?(files, fn file ->
            {:ok, wasm_file} = Ipfs.get(conn, file)
            EthCalls.sg_use_eth_calls?(wasm_file)
          end)

        {deployment_id, has_eth_calls}
      end)
      |> IO.inspect()
      |> Enum.filter(fn {_deployment_id, has_calls} -> has_calls end)
      |> Enum.count()

    percent =
      case result do
        0 -> 0
        r -> count * 100 / r
      end

    IO.puts("#{percent}% use eth-call")
  end
end
