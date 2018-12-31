defmodule MetaloveTest do
  use ExUnit.Case
  doctest Metalove

  test "greets the world" do
    assert Metalove.hello() == :world
  end
end
