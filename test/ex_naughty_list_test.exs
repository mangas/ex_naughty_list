defmodule NaughtyListTest do
  use ExUnit.Case
  # doctest NaughtyList

  describe "handles file parsing" do
    test "substreams" do
      file = "QmSgZzWNBMYhAjEseWvcmyo54XTCqxWEjXV6zADB3omKUt"

      input = """
      dataSources:
        - kind: substreams
          mapping:
            apiVersion: 0.0.6
            kind: substreams/graph-entities
          name: contract-reviewer
          network: mainnet
          source:
            package:
              file:
                /: /ipfs/#{file}
              moduleName: graph_out
      description: >-
        Ethereum Contract Usage Analytics with Events and Creations (from January 2025
        onwards)
      repository: https://github.com/PaulieB14/ETH-contract-reviewer
      schema:
        file:
          /: /ipfs/QmQVPHJtAdUw2AbVF3sdH5fEod3iVLeRfL5ZEcPwXVExKZ
      specVersion: 0.0.5
      """

      {:ok, input} = YamlElixir.read_from_string(input)

      # assert EthCalls.parse_substreams(input) == [file]
      assert EthCalls.parse_handlers(input) == [file]
      assert EthCalls.parse_datasources(input) == [file]
    end
  end
end
