defmodule StopLight.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: :stop_light,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mdns, "~> 0.1"},
      {:poison, "~> 3.1"},
      {:elli, git: "https://github.com/knoxen/elli.git", branch: "knoxen"}
    ] ++ deps(@target)
  end

  defp deps("host"), do: []

  defp deps(_) do
    [
      {:nerves_network, "~> 0.3"},
      {:elixir_ale, "~> 1.0"}
    ]
  end
end
