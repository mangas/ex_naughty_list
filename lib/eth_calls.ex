require Logger

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
        Logger.debug("processing deployment_id: #{id}")
        {:ok, bs} = Ipfs.get_retry(conn, id)

        {:ok, manifest} =
          YamlElixir.read_from_string(bs)

        {id,
         parse_handlers(manifest)
         |> Enum.uniq()}
    end)
  end

  def parse_templates(%{
        "templates" => ts
      }),
      do:
        Enum.map(ts, fn
          %{
            "mapping" => %{
              "file" => %{"/" => <<"/ipfs/">> <> handler}
            }
          } ->
            handler
        end)

  def parse_templates(_), do: []

  def parse_datasources(%{"dataSources" => ds}),
    do:
      Enum.map(ds, fn
        %{"kind" => "substreams"} = ds ->
          parse_substreams(ds)

        %{
          "mapping" => %{
            "file" => %{"/" => <<"/ipfs/">> <> handler}
          }
        } ->
          handler
      end)

  def parse_datasources(_), do: []

  def parse_substreams(%{
        "kind" => "substreams",
        "source" => %{
          "package" => %{
            "file" => %{"/" => <<"/ipfs/">> <> handler}
          }
        }
      }),
      do: handler

  def parse_handlers(manifest),
    do: parse_datasources(manifest) ++ parse_templates(manifest)

  @eth_call ~c"ethereum.call"
  def sg_use_eth_calls?(compiled_wasm) when is_binary(compiled_wasm) do
    match = :binary.match(compiled_wasm, :binary.list_to_bin(@eth_call))

    case match do
      :nomatch -> false
      _ -> true
    end
  end
end
