defmodule StopLight.Network do
  @target System.get_env("MIX_TARGET")
  @interface "wlan0"
  @dns_ping 'google.com'

  require Logger

  ## ===============================================================================================
  ##
  ##  GenServer
  ##
  ## ===============================================================================================
  use GenServer

  ## ===============================================================================================
  ##
  ##  Client
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Child specification for starting server
  ## -----------------------------------------------------------------------------------------------
  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :supervisor}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Start
  ## -----------------------------------------------------------------------------------------------
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init client
  ## -----------------------------------------------------------------------------------------------
  def init([]) do
    {:ok, setup(@target)}
  end

  defp setup("host"), do: %{}

  defp setup(_) do
    SystemRegistry.register()
    Nerves.Network.setup(@interface)
    config_mdns()
    :os.cmd('epmd -daemon')
    %{connected: false, ip_addr: nil}
  end

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Peek at state
  ## -----------------------------------------------------------------------------------------------
  def ip_addr, do: GenServer.call(__MODULE__, :ip_addr)
  def connected?, do: GenServer.call(__MODULE__, :connected?)

  ## ===============================================================================================
  ##
  ##  GenServer call
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Reveal state
  ## -----------------------------------------------------------------------------------------------
  def handle_call(:ip_addr, _from, state), do: {:reply, state.ip_addr, state}
  def handle_call(:connected?, _from, state), do: {:reply, state.connected, state}

  ## ===============================================================================================
  ##
  ##  GenServer info
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  IP addr changes
  ## -----------------------------------------------------------------------------------------------
  def handle_info({:system_registry, :global, registry}, state) do
    ip_addr = get_in(registry, [:state, :network_interface, @interface, :ipv4_address])

    if ip_addr != state.ip_addr, do: mdns_set_ip(ip_addr)

    connected =
      if !state.connected do
        dns = :inet_res.gethostbyname(@dns_ping)
        match?({:ok, {:hostent, @dns_ping, [], :inet, 4, _}}, dns)
      else
        state.connected
      end

    if connected and !state.connected do
      mdns_restart(ip_addr)
      node_restart()
    end

    {:noreply, %{state | ip_addr: ip_addr, connected: connected || false}}
  end

  ## ===============================================================================================
  ##
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Access network config params
  ## -----------------------------------------------------------------------------------------------
  defp network, do: :stop_light |> Application.get_env(:network)
  defp domain, do: network()[:mdns_domain]
  defp node_name, do: network()[:node_name]

  ## -----------------------------------------------------------------------------------------------
  ##  Configure mDNS
  ## -----------------------------------------------------------------------------------------------
  defp config_mdns do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: domain(),
      data: :ip,
      ttl: 120,
      type: :a
    })
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Restart erlang distribution
  ## -----------------------------------------------------------------------------------------------
  defp node_restart do
    :net_kernel.stop()
    node = :"#{node_name()}@#{domain()}"

    case :net_kernel.start([node]) do
      {:ok, _} ->
        Logger.info("StopLight.Network start distribution on node #{node}")

      {:error, reason} ->
        Logger.warn("StopLight.Network start distribution failed #{inspect(reason)}")
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Restart Mdns.Server
  ## -----------------------------------------------------------------------------------------------
  defp mdns_restart(ip_addr) do
    Mdns.Server.stop()
    :timer.sleep(500)
    Mdns.Server.start(interface: ip_tuple(ip_addr))
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Set mDNS ip addr
  ## -----------------------------------------------------------------------------------------------
  defp mdns_set_ip(ip_addr) do
    Logger.info("StopLight.Network mDNS ip= #{ip_addr}")

    ip_addr
    |> ip_tuple
    |> Mdns.Server.set_ip()
  end

  defp ip_tuple(ip_addr) do
    ip_addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end
