defmodule NaughtyListTest do
  use ExUnit.Case
  doctest NaughtyList

  test "greets the world" do
    assert NaughtyList.hello() == :world
  end
end
