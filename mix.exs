defmodule Pipette.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pipette,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
end
