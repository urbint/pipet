defmodule PipetTest do
  use ExUnit.Case, async: true

  import Pipet

  describe "pipet" do
    def inc(x), do: x + 1
    def add(x, y), do: x + y
    def return_true(), do: true
    def return_false(), do: false
    def return_ok_tuple(), do: {:ok, 7}

    test "conditionally pipes through the bodies of succeeding tests" do
      result =
        pipet 1 do
          inc()                            # 2
          if return_true(), do: inc()      # 3
          if return_false(), do: inc()     # 3
          if return_true(), do: inc()      # 4
          if return_true(), do: add(3)     # 7
          unless return_true(), do: add(3) # 7
          cond do
            return_true()  -> inc()        # 8
            return_false() -> inc()
          end
          case return_true() do
            true  -> inc()                 # 9
            false -> add(2)
          end

          with {:ok, x} <- return_ok_tuple() do
            add(x)                         # 16
          end

          with :error <- return_ok_tuple() do
            inc()
          else
            {:ok, x} ->
              add(x)                       # 23
          end
        end

      assert result == 23
    end

    test "supports `else` blocks for `if`" do
      result =
        pipet 1 do
          if return_false() do
            add(2)
          else
            inc() # 2
          end
        end

      assert result == 2
    end

    test "supports `else` blocks for `unless` (but you shouldn't use them)" do
      result =
        pipet 1 do
          unless return_false() do
            add(2) # 3
          else
            inc()
          end
        end

      assert result == 3
    end

  end
end
