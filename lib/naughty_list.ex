defmodule NaughtyList.Cli do
  require Logger

  def main(args) do
    case args do
      ["list-subgraphs"] ->
        load_sg_query_data()

      [] ->
        print_help()

      ["help"] ->
        print_help()

      ["run"] ->
        File.read!("query_result_2025-05-21T07_47_15.203737041Z.json")
        |> parse_query_data()
        |> calculate_naughties()

      ["run" | tail] ->
        calculate_naughties(tail)
    end
  end

  def print_help do
    IO.puts("""
    naughty_list help menu:

    help: prints this menu
    run: Calculates the naughty list of subgraphs that use eth-calls from the query results export
    run DEPLOYMENT_ID [DEPLOYMENT_ID...]: Calculates the naughty list of subgraphs that use eth-calls from the provided list
    """)
  end

  def parse_query_data(file_content) do
    {:ok, data} = JSON.decode(file_content)

    Enum.map(data, fn dp ->
      {count, _} = Integer.parse(String.replace(dp["queryCount"], ",", ""), 10)
      {dp["info_subgraph_deployment_ipfs_hash"], count}
    end)
    |> Enum.reject(fn
      {"", _c} -> true
      _ -> false
    end)
    |> Enum.sort_by(fn {_hash, count} -> count end, :desc)
    |> Enum.take(1000)
  end

  def load_sg_query_data do
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

  # empty means just read the sg-query-data.json file
  def normalize([]), do: load_sg_query_data()

  # list of tuples
  def normalize([{_id, _count} | _tail] = args), do: args

  # just deployments ids
  def normalize(args) do
    Enum.map(args, fn id -> {id, 0} end)
  end

  def calculate_naughties(args) do
    sgs = normalize(args) |> Map.new()

    conn = Ipfs.conn()
    count = Enum.count(sgs)

    result =
      EthCalls.sg_find_handles(Map.keys(sgs))
      |> Enum.map(fn {deployment_id, files} ->
        has_eth_calls =
          Enum.any?(files, fn file ->
            {:ok, wasm_file} = Ipfs.get_retry(conn, file)
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
