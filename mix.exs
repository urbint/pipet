defmodule Pipet.Mixfile do
  use Mix.Project

  @version "0.1.4"

  def project do
    [
      app: :pipet,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        main: "Pipet",
        source_url: "https://github.com/urbint/pipet",
      ],
     package: package(),
     description: description(),
    ]
  end

  defp deps do
    [
      {:cortex, "~> 0.2.1", only: [:test, :dev], runtime: !ci_build?()},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ex_dash, "~> 0.1", only: [:dev]},
    ]
  end

  defp ci_build?, do: System.get_env("CI") != nil

  defp description do
    """
    A library for conditionally chaining data through a series of operations
    """
  end

  defp package do
    [
      name: :pipet,
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "History.md",
        "LICENSE"
      ],
      maintainers: [
        "Griffin Smith <grfn at urbint dot com>",
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/urbint/pipet"},
    ]
  end
end
