defmodule NaughtyList.Cli do
  def main(args) do
    conn = Ipfs.conn()

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
  end
end
