defmodule EthCalls do
  defmodule EthCalls.GraphManifest do
    @type t :: %__MODULE__{
            datasources: list(EthCalls.DataSource.t())
          }
    defstruct datasources: []
  end

  defmodule EthCalls.DataSource do
    @type t :: %__MODULE__{
            files: %{String.t() => String.t()}
          }
    defstruct files: %{}
  end

  # Get the deployments IDs, return the related handle files
  @spec sg_find_handles(list(String.t())) :: list(String.t())
  def sg_find_handles(deployment_ids) when is_list(deployment_ids) do
    conn = Ipfs.conn()

    Enum.map(deployment_ids, fn
      id ->
        {:ok, bs} = Ipfs.get(conn, id)

        {:ok, manifest} =
          YamlElixir.read_from_string(bs)

        ds =
          Enum.map(manifest["dataSources"], fn %{
                                                 "mapping" => %{
                                                   "file" => %{"/" => <<"/ipfs/">> <> handler}
                                                 }
                                               } ->
            handler
          end)

        templates =
          Enum.map(manifest["templates"], fn %{
                                               "mapping" => %{
                                                 "file" => %{"/" => <<"/ipfs/">> <> handler}
                                               }
                                             } ->
            handler
          end)

        {id,
         Enum.concat(templates, ds)
         |> IO.inspect()
         |> Enum.uniq()}
    end)
  end

  @eth_call ~c"ethereum.call"
  def sg_use_eth_calls?(compiled_wasm) when is_binary(compiled_wasm) do
    match = :binary.match(compiled_wasm, :binary.list_to_bin(@eth_call)) |> IO.inspect()

    case match do
      :nomatch -> false
      _ -> true
    end

    # String.contains?(compiled, @eth_call)
    # Enum.member?(compiled, @eth_call)
    # IO.inspect(compiled_wasm, binaries: :as_binary)

    # call in to_charlist(compiled_wasm)
  end
end
