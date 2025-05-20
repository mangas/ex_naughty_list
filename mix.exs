defmodule NaughtyList.MixProject do
  use Mix.Project

  def project do
    [
      app: :naughty_list,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      releases: releases()
    ]
  end

  def escript do
    [
      main_module: NaughtyList.Cli
    ]
  end

  def releases do
    [
      naughty_list: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64],
            macos_aarch64: [os: :darwin, cpu: :aarch64],
            linux: [os: :linux, cpu: :x86_64],
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 2.11"},
      {:poison, "~> 6.0"},
      {:httpoison, "~> 2.2"},
      {:burrito, "~> 1.3.0"}
    ]
  end
end
