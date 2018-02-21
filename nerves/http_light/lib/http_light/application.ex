defmodule HttpLight.Application do
  use Application

  ## ===============================================================================================
  ##
  ##  Application
  ##
  ## ===============================================================================================
  def start(_type, _args) do
    Process.register(self(), __MODULE__)

    children = [
      StopLight.Network,
      StopLight.Lights,
      StopLight.DevicePairing,
      StopLight.Login.Manager,
      StopLight.Elli.ChildSpec.spec(:http)
    ]

    opts = [strategy: :one_for_one, name: HttpLight.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
