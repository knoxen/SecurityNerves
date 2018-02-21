defmodule StopLight.Login.Manager do
  alias StopLight.Login.Credentials
  alias StopLight.Lights

  @target System.get_env("MIX_TARGET")

  ## ===============================================================================================
  ##
  ##  Manage login
  ##
  ## ===============================================================================================
  use GenServer

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##
  ## -----------------------------------------------------------------------------------------------
  def login(user), do: GenServer.call(__MODULE__, {:login, user})
  def logged_in?, do: GenServer.call(__MODULE__, :logged_in?)
  def touch, do: GenServer.call(__MODULE__, :touch)
  def logout, do: GenServer.call(__MODULE__, :logout)

  ## ===============================================================================================
  ##
  ## Client
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Child specification for starting server
  ## -----------------------------------------------------------------------------------------------
  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :supervisor}
  end

  ## -----------------------------------------------------------------------------------------------
  ##
  ## -----------------------------------------------------------------------------------------------
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init
  ## -----------------------------------------------------------------------------------------------
  def init(_args) do
    setup @target

    # 4RU the credentials file can end up empty. This behavior is independent of the StopLight
    # application's implementation as it has been confirmed via File.write from a remsh.
    # This workaround ensures an empty file is removed rather than processed as valid credentials
    if Credentials.exists? && Credentials.read == "", do: Credentials.remove
    
    Lights.blink(
      if Credentials.exists?() do
        :green
      else
        :red
      end
    )

    {:ok, [login: []]}
  end

  def handle_call({:login, username}, _from, state) do
    status = [user: username, login_time: login_time(), login_touch: login_monotonic()]
    {:reply, "ok", state |> Keyword.put(:login, status)}
  end

  def handle_call(:logged_in?, _from, state) do
    {:reply, state |> Keyword.get(:login) != [], state}
  end

  def handle_call(:touch, _from, state) do
    state
    |> Keyword.get(:login)
    |> case do
      [] ->
        {:reply, :ignore, state}

      status ->
        update = status |> Keyword.put(:login_touch, login_monotonic())
        {:reply, "ok", state |> Keyword.put(:login, update)}
    end
  end

  def handle_call(:logout, _from, state) do
    {:reply, "ok", state |> Keyword.put(:login, [])}
  end

  def handle_call(_term, _from, state) do
    {:reply, :ignore, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp setup("host") do
    {"host"}
  end

  defp setup(_target) do
    {"device"}
  end

  defp login_time, do: :erlang.system_time(:second)
  defp login_monotonic, do: :erlang.monotonic_time(:second)

end
