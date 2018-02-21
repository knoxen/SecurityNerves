defmodule SrpcLight.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  Mix.shell().info([
    :green,
    """
    Mix environment
      MIX_TARGET: #{@target}
      MIX_ENV:    #{Mix.env()}
      Interface:  SRPC
    """,
    :reset
  ])

  def project do
    [
      app: :srpc_light,
      version: "0.1.0",
      elixir: "~> 1.4",
      target: @target,
      archives: [nerves_bootstrap: "~> 0.7"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(@target),
      deps: deps()
    ]
  end

  def application do
    [mod: {SrpcLight.Application, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:stop_light, path: "../stop_light"},
      {:srpc_elli, path: "local/srpc_elli", compile: false},
      {:srpc_srv, path: "local/srpc_srv", compile: false, override: true},
      {:srpc_lib, path: "local/srpc_lib", compile: false, override: true},
      {:entropy_string, "~> 1.0"},
      {:kncache, git: "https://github.com/knoxen/kncache.git", tag: "0.12.0"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host"), do: []

  defp deps(target) do
    [
      {:shoehorn, "~> 0.2"},
      {:nerves, "~> 0.9", runtime: false},
      {:nerves_runtime, "~> 0.4"}
    ] ++ system(target)
  end

  defp system("rpi"), do: [{:nerves_system_rpi, ">= 0.0.0", runtime: false}]
  defp system("rpi0"), do: [{:nerves_system_rpi0, ">= 0.0.0", runtime: false}]
  defp system("rpi2"), do: [{:nerves_system_rpi2, ">= 0.0.0", runtime: false}]
  defp system("rpi3"), do: [{:nerves_system_rpi3, ">= 0.0.0", runtime: false}]
  defp system("bbb"), do: [{:nerves_system_bbb, ">= 0.0.0", runtime: false}]
  defp system("ev3"), do: [{:nerves_system_ev3, ">= 0.0.0", runtime: false}]
  defp system("qemu_arm"), do: [{:nerves_system_qemu_arm, ">= 0.0.0", runtime: false}]
  defp system("x86_64"), do: [{:nerves_system_x86_64, ">= 0.0.0", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")

  # We do not invoke the Nerves Env when running on the Host
  defp aliases("host"), do: []

  defp aliases(_target) do
    [
      # Add custom mix aliases here
    ]
    |> Nerves.Bootstrap.add_aliases()
  end
end
