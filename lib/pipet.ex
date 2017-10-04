defmodule Pipet do
  @moduledoc """
  Macro for conditionally piping a value through a series of expressions.

  ## Prior art

  Pipet was heavily inspired by, and would not exist without:

  - [clojure's `cond->` macro](https://clojuredocs.org/clojure.core/cond-%3E)
  - [packthread for clojure](https://github.com/maitria/packthread)

  """

  @doc """
  Conditionally pipe a value through a series of operations.

  `pipes` is a series of conditional expressions. At each step of the way, if the condition
  succeeds, then the value will be applied as the first argument of the last expression of the body
  of the condition as in `|>`, and if the condition fails the expression will be skipped. The
  supported forms of conditional expressions are:

  - `if`
  - `unless`
  - `cond`
  - `case`
  - `with`

  Raw function calls are also supported, in which case the value is piped through just like in `|>`

  ## Examples

  Basic `if` conditions are supported:

      pipet [1, 2, 3] do
        if do_increment?(), do: Enum.map(& &1 + 1)
        if do_double?(),    do: Enum.map(& &1 * 1)
        if do_string?(),    do: Enum.map(&to_string/1)
      end

  `case` and `cond` use whichever branch succeeds:

      pipet [1, 2, 3] do
        case operation do
          :increment -> Enum.map(& &1 + 1)
          :double    -> map(& &1 * 1)
          :string    -> Enum.map(&to_string/1)
        end
      end

  `with` pipes through the `do` block if all pattern matches succeed, or uses the first successful
  `else` block if a pattern fails.

      pipet [1, 2, 3] do
        with {:ok, x} <- get_value() do
          Enum.map(& &1 + x)
        else
          :something_else -> Enum.map(& &1 + 1)
        end
      end

  Conditional expressions can be combined with bare function calls, which will always execute:

      pipet ["1", "2", "3"] do
        String.to_integer()
        if do_increment?(), do: Enum.map(& &1 + 1)
      end

  Multi-expression bodies pipe through the last expression:

      pipet [1, 2, 3] do
        if do_add_num?() do
          num = 3
          Enum.map(& &1 + num)
        end

        case something() do
          {:ok, x} ->
            x = x + 1
            Enum.map(& &1 + x)

          :error ->
            Enum.map(& &1 - 2)
        end
      end

  ## Notes

  - `pipet` evaluates conditions in order, not all at once. For example, the following:

          def print_hello_and_return_true() do
            IO.puts "hello"
            true
          end

          pipet 1 do
            if print_hello_and_return_true() do
              IO.puts "world"
              increment()
            end
            unless print_hello_and_return_true() do
              IO.puts "goodbye"
            end
          end

    prints:

          > hello
          > world
          > hello

  - the rules for `case` and `with` are as usual - if none of the branches of a `case` block or of
    an `else` block in a `with` statement match a `CaseClauseError` or `WithClauseError`
    respectively will be thrown. If you want a fallthrough case, you can provide a call to the
    identity function:

          pipet 1 do
            case {:foo, :bar} do
              :never_matches -> increment()
              _ -> (& &1).()
            end
          end

          pipet 1 do
            with {:ok, x} <- :some_tuple do
              increment()
            else
              :doesnt_match -> increment()
              _ -> (& &1).()
            end
          end

  """
  @spec pipet(Macro.t, do: [Macro.t]) :: Macro.t
  defmacro pipet(subject, do: pipes) do
    pipes =
      case pipes do
        {:__block__, _, exprs} -> exprs
        expr                   -> [expr]
      end

    Enum.reduce Stream.with_index(pipes), subject, fn {expr, idx}, acc ->
      var =
        Macro.var(:"V#{idx}", __MODULE__)

      quote do
        unquote(var) = unquote(acc)
        unquote(pipet_expr(var, expr))
      end
    end
  end


  @spec pipet_expr(Macro.t, Macro.t) :: Macro.t
  defp pipet_expr(value, {:if, _, [condition, opts]}) do
    [true_body, false_body] =
      Enum.map([:do, :else], fn opt ->
        case Keyword.fetch(opts, opt) do
          {:ok, body} -> Macro.pipe(value, body, 0)
          _           -> value
        end
      end)

    quote do
      if unquote(condition) do
        unquote(true_body)
      else
        unquote(false_body)
      end
    end
  end

  defp pipet_expr(value, {:unless, env, [condition, opts]}) do
    [false_body, true_body] =
      Enum.map([:do, :else], &Keyword.get(opts, &1))

    put_ifex = fn
      kw, _, nil   -> kw
      kw, key, val -> Keyword.put(kw, key, val)
    end

    new_opts =
      []
      |> put_ifex.(:else, false_body)
      |> put_ifex.(:do, true_body)

    pipet_expr(value, {:if, env, [condition, new_opts]})
  end

  defp pipet_expr(value, {:cond, _, [[do: conditions]]}) do
    quote do
      cond do: unquote(pipe_arrows(value, conditions))
    end
  end

  defp pipet_expr(value, {:case, _, [subj, [do: conditions]]}) do
    quote do
      case unquote(subj), do: unquote(pipe_arrows(value, conditions))
    end
  end

  defp pipet_expr(value, {:with, _, args}) do
    {conds, [opts]} =
      Enum.split(args, length(args) - 1)

    piped_opts =
      case Keyword.fetch(opts, :else) do
        {:ok, else_body} -> [else: pipe_arrows(value, else_body)]
        _                -> []
      end
      |> Keyword.put(:do, Macro.pipe(value, opts[:do], 0))

    with_args = conds ++ [piped_opts]

    quote do: with unquote_splicing(with_args)
  end

  defp pipet_expr(value, fcall) do
    Macro.pipe(value, fcall, 0)
  end

  defp pipe_arrows(value, arrows) do
    Enum.flat_map arrows, fn {:->, _, [lhs, rhs]} ->
      rhs =
        case rhs do
          {:__block__, _, exprs} ->
            last =
              List.last(exprs)
            butlast =
              Enum.slice(exprs, 0..-2)

            quote do
              unquote_splicing(butlast)
              unquote(Macro.pipe(value, last, 0))
            end

          expr ->
            Macro.pipe(value, expr, 0)
        end

      quote do
        unquote_splicing(lhs) -> unquote(rhs)
      end
    end
  end
end
