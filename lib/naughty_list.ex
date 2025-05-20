defmodule NaughtyList.Cli do
  def main(args) do
    case args do
      ["list-subgraphs"] -> find_pinned_subgraphs()
      [] -> print_help()
      ["help"] -> print_help()
      ["run"] -> calculate_naughties([])
      ["run" | tail] -> calculate_naughties(tail)
    end
  end

  def print_help do
    IO.puts("""
    naughty_list help menu:

    list-subgraphs: Tries to find all subgraphs pinned to IPFS (might take a while, it's slow)
    help: prints this menu
    run: Calculates the naughty list of subgraphs that use eth-calls
    """)
  end

  def find_pinned_subgraphs do
    # "https://ipfs.network.thegraph.com/ipfs/api/v0/pin/ls?size=true&stream=true"
    # conn = Ipfs.conn()
    # Ipfs.list_pinned(conn) |> IO.inspect()

    {:ok, bs} = File.read("sg-query-data.json")

    # {
    # "response": {
    #   "queryDatapoints": {
    #     "datapoints": [

    {:ok, %{"response" => %{"queryDatapoints" => %{"datapoints" => datapoints}}}} =
      JSON.decode(bs)

    Enum.map(datapoints, fn dp ->
      {count, _} = Integer.parse(dp["queryCount"], 10)
      {dp["subgraphDeploymentIpfsHash"], count}
    end)
    |> Enum.reject(fn
      {"", _c} -> true
      _ -> false
    end)
    |> Enum.sort_by(fn {_hash, count} -> count end, :desc)
  end

  def calculate_naughties(args) do
    # sgs =
    #   [
    #     {"QmdKXcBUHR3UyURqVRQHu1oV6VUkBrhi2vNvMx3bNDnUCc", 0},
    #     {"QmY67iZDTsTdpWXSCotpVPYankwnyHXNT7N95YEn8ccUsn", 0}
    #   ]
    #   |> Map.new()
    sgs =
      case args do
        [] ->
          find_pinned_subgraphs()

        args ->
          Enum.map(args, fn id -> {id, 0} end)
      end

    sgs = Map.new(sgs)

    conn = Ipfs.conn()
    count = Enum.count(sgs)

    result =
      EthCalls.sg_find_handles(Map.keys(sgs))
      |> Enum.map(fn {deployment_id, files} ->
        has_eth_calls =
          Enum.any?(files, fn file ->
            {:ok, wasm_file} = Ipfs.get(conn, file)
            EthCalls.sg_use_eth_calls?(wasm_file)
          end)

        {deployment_id, has_eth_calls}
      end)
      |> Map.new()
      |> Map.merge(sgs, fn _key, value1, value -> {value, value1} end)

    eth_calls =
      result
      |> Enum.count(fn {_deployment_id, {_query_count, has_calls}} -> has_calls end)

    Map.to_list(result)
    |> Enum.sort_by(fn {_id, {count, _eth_calls}} -> count end, :desc)
    |> Enum.each(fn {id, {count, eth_calls}} ->
      IO.puts("#{id},#{count},#{eth_calls}")
    end)

    percent =
      case eth_calls do
        0 -> 0
        r -> r * 100 / count
      end

    IO.puts("#{percent}% use eth-call, that's #{eth_calls}/#{count} subgraphs")
  end
end
