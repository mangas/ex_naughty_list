defmodule NaughtyList.Cli do
  def main(args) do
    conn = Ipfs.conn()

    count = Enum.count(args)

    result =
      EthCalls.sg_find_handles(args)
      # |> IO.inspect()
      |> Enum.map(fn {deployment_id, files} ->
        has_eth_calls =
          Enum.any?(files, fn file ->
            {:ok, wasm_file} = Ipfs.get(conn, file)
            EthCalls.sg_use_eth_calls?(wasm_file)
          end)

        {deployment_id, has_eth_calls}
      end)
      |> IO.inspect()
      |> Enum.filter(fn {deployment_id, has_calls} -> has_calls end)
      |> Enum.count()

    percent =
      case result do
        0 -> 0
        r -> count * 100 / r
      end

    IO.puts("#{percent}% use eth-call")
  end
end
