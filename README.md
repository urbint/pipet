# Pipette [![CircleCI](https://circleci.com/gh/urbint/pipette/tree/master.svg?style=svg)](https://circleci.com/gh/urbint/pipette/tree/master)

A library for conditionally chaining data through a series of operations

## Installation

Add `pipette` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:pipette, "~> 0.1.0"}
  ]
end
```

[Documentation can be found here](https://hexdocs.pm/pipette).

Elixir's `|>` (pipe) operator is one of its best features; it mixes extremely
well with a functional, immutable style of programming. It tends to break down,
however, when you want to perform the operations in a pipeline only sometimes,
for instance in response to an `options` keyword passed to your function. How
many times have you wanted to perform something in a pipeline conditionally, but
instead had to write something like the following:

```elixir
def get_names(people, options \\ []) do
  results =
    people
    |> Stream.map(fn %Person{name: name} -> name end)

  results =
    if Keyword.fetch(options, :upcase) do
      people
      |> Stream.map(&String.upcase/1)
    else
      people
    end

  Enum.to_list(results)
end
```

Pipette provides a single macro, `pipette`, which extends the semantics of
piping to function properly with all of elixir's built-in conditional
expressions in a simple, clean, and obvious way. The code sample above could be
rewritten with `pipette` like this:

```elixir
import Pipette

def get_names(people, options \\ []) do
  pipette people do
    Stream.map(fn %Person{name: name} -> name end)

    if Keyword.fetch(options, :upcasee) do
      Stream.map(&String.upcase/1)
    end

    Enum.to_list()
  end
end
```

Way cleaner! No variable rebinding, no pointless `else` block for the `if`
statement, just the code that matters.

Pipette works with all of Elixir's built-in conditional operators in addition to
just `if`. All the following should work exactly as you expect them to:

- `if`
- `unless`
- `case`
- `cond`

## Prior Art

Pipette originally started as a port of the Clojure standard library's [`cond->`
macro][cond->], before very quickly outgrowing the feature set of that macro
into something that very closely resembles [packthread][packthread], also for
Clojure. Acknowledgements go to [@richhickey][] for the former and [@eraserhd][]
for the latter.

[cond->]: https://clojuredocs.org/clojure.core/cond-%3E
[packthread]: https://github.com/maitria/packthread
[@richhickey]: https://github.com/richhickey
[@eraserhd]: https://github.com/eraserhd


## License

Copyright 2017 Urbint

Licensed under the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
