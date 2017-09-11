defmodule MagicPipeTest do
  use ExUnit.Case
  doctest MagicPipe

  test "greets the world" do
    assert MagicPipe.hello() == :world
  end
end
