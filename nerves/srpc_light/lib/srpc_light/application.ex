defmodule SrpcLight.Application do
  use Application

  @target System.get_env("MIX_TARGET") || "host"

  ## ===============================================================================================
  ##
  ##  Application
  ##
  ## ===============================================================================================
  def start(_type, _args) do
    Process.register(self(), __MODULE__)

    :ok = srpc_init()

    caches = Application.get_env(:kncache, :caches)

    children = [
      StopLight.Network,
      StopLight.Lights,
      StopLight.DevicePairing,
      StopLight.Login.Manager,
      StopLight.Elli.ChildSpec.spec(:http),
      {:kncache, [caches]}
    ]

    opts = [strategy: :one_for_one, name: SrpcLight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp srpc_init do
    srpc_file = Application.get_env(:srpc_light, :srpc_file)

    srpc_file[:path]
    |> Keyword.fetch!(
      @target
      |> case do
        "host" -> :host
        _ -> :device
      end
    )
    |> Path.join(srpc_file[:name])
    |> File.read!()
    |> :srpc_lib.init()
  end
end
