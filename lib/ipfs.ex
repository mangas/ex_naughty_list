defmodule Ipfs do
  require Logger
  alias HTTPoison.{Response, Error}

  defmodule Ipfs.IPFS do
    @typedoc "Represents the endpoint to hit. Required as the first argument of most functions."
    @type t :: %__MODULE__{
            scheme: String.t(),
            host: String.t(),
            port: pos_integer,
            base: String.t() | nil
          }
    defstruct ~w(scheme host port base)a
  end

  def list_pinned(conn) do
    # "https://ipfs.network.thegraph.com/ipfs/api/v0/pin/ls?size=true&stream=true"
    request(
      conn,
      "pin/ls",
      &HTTPoison.post(&1, [], [], params: %{"size" => true, "stream" => true})
    )
  end

  def get_retry(conn, file_id) do
    case get(conn, file_id) do
      {:error, error} ->
        Logger.error("unable to get file from ipfs (#{file_id}), error: #{error}")
        :timer.sleep(35000)
        get_retry(conn, file_id)

      result ->
        result
    end
  end

  @doc """
  High level function allowing to perform GET requests to the node.

  A `path` has to be provided, along with an optional list of `params` that are
  dependent on the endpoint that will get hit.
  """
  def get(conn, id) do
    request(
      conn,
      "cat",
      &HTTPoison.post(&1, [], [], params: %{"arg" => id})
    )
  end

  defp request(conn, path, requester) do
    conn
    |> to_string()
    |> pipe(&"#{&1}/#{path}")
    |> requester.()
    |> to_result
  end

  def conn(),
    do: %Ipfs.IPFS{scheme: "https", host: "api.thegraph.com", port: 443, base: "ipfs/api/v0"}

  defp to_result({:ok, %Response{status_code: 200, body: b}}) do
    {:ok, b}
  end

  defp to_result({:ok, %Response{status_code: c, body: b}}) do
    {:error, "Error status code: #{c}, #{b}"}
  end

  defp to_result({:error, %Error{reason: err}}) do
    {:error, err}
  end

  @spec pipe(any, (any -> any)) :: any
  def pipe(arg, f), do: f.(arg)

  defimpl String.Chars, for: Ipfs.IPFS do
    def to_string(%{scheme: scheme, host: host, port: port, base: base}) do
      ["#{scheme}://#{host}:#{port}", base]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("/")
    end
  end
end
