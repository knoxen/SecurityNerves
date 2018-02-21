defmodule StopLight.Lights do
  @moduledoc """
  CxTBD Documentation for StopLight.Lights.
  """

  alias ElixirALE.GPIO

  ## ===============================================================================================
  ##
  ##  Module constants
  ##
  ## ===============================================================================================
  @target System.get_env("MIX_TARGET")

  @off 0
  @on 1
  # Blink rate in milliseconds
  @blink 500

  @red_gpio 9
  @yellow_gpio 10
  @green_gpio 11

  ## ===============================================================================================
  ##
  ## Macros
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Validate light (for use in guards)
  ## -----------------------------------------------------------------------------------------------
  defmacro valid_light?(light) do
    quote do
      unquote(light) == :red or unquote(light) == :yellow or unquote(light) == :green
    end
  end

  ## ===============================================================================================
  ##
  ##  GenServer
  ##
  ##  Control GPIO lights (switch, blink, status)
  ##
  ## ===============================================================================================
  use GenServer

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
  ##  Start with light, or default to red
  ## -----------------------------------------------------------------------------------------------
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init
  ##
  ##  State: {light, pids, blink_timer}
  ##    light - atom of light either on or blinking
  ##    pids - map of pids controlling the GPIO pins for each light
  ##    blink_timer - timer ref when a light is blinking; o/w :no_blink
  ##
  ## -----------------------------------------------------------------------------------------------
  def init([]) do
    pids =
      @target
      |> setup
      |> turn_off(:yellow)
      |> turn_off(:green)
      |> turn_on(:red)

    {:ok, {:red, pids, :no_blink}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Host target isn't running any real lights. The pids are actually light status as string
  ## -----------------------------------------------------------------------------------------------
  defp setup("host") do
    %{red: nil, yellow: nil, green: nil}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Device target pids point to GPIO processes that are managing a particular light
  ## -----------------------------------------------------------------------------------------------
  defp setup(_target) do
    {:ok, red} = GPIO.start_link(@red_gpio, :output)
    {:ok, yellow} = GPIO.start_link(@yellow_gpio, :output)
    {:ok, green} = GPIO.start_link(@green_gpio, :output)
    %{red: red, yellow: yellow, green: green}
  end

  ## ===============================================================================================
  ##
  ## Public API
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ## -----------------------------------------------------------------------------------------------
  def status(), do: GenServer.call(__MODULE__, :status)

  def status(light) when valid_light?(light), do: GenServer.call(__MODULE__, {:status, light})
  def status(_light), do: :invalid

  ## -----------------------------------------------------------------------------------------------
  ## -----------------------------------------------------------------------------------------------
  def switch(light) when valid_light?(light), do: GenServer.call(__MODULE__, {:switch, light})
  def switch(_light), do: :invalid

  ## -----------------------------------------------------------------------------------------------
  ## -----------------------------------------------------------------------------------------------
  def blink(light) when valid_light?(light), do: GenServer.call(__MODULE__, {:blink, light})
  def blink(_light), do: :invalid

  ## -----------------------------------------------------------------------------------------------
  ## -----------------------------------------------------------------------------------------------
  def log_action(action, light \\ "") do
    case @target do
      "host" -> GenServer.cast(__MODULE__, {:log_action, action, light})
      _ -> :ignore
    end
  end

  # Exposing these calls is a purposeful mistake
  ## -----------------------------------------------------------------------------------------------
  ## -----------------------------------------------------------------------------------------------
  def on(light) when valid_light?(light), do: GenServer.call(__MODULE__, {:on, light})
  def on(_light), do: :invalid

  def off(light) when valid_light?(light), do: GenServer.call(__MODULE__, {:off, light})
  def off(_light), do: :invalid

  ## ===============================================================================================
  ##
  ##  Call messages
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  status
  ## -----------------------------------------------------------------------------------------------
  def handle_call(:status, _from, state) do
    log_action("status")
    {:reply, {:ok, lights_status(state)}, state}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  switch light
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:switch, light}, _from, {state_light, state_pids, :no_blink}) do
    pids =
      state_pids
      |> turn_off(state_light)
      |> turn_on(light)

    log_action("switch", light)
    {:reply, {:ok, light}, {light, pids, :no_blink}}
  end

  def handle_call({:switch, light}, from, {current, pids, blink_timer}) do
    handle_call({:switch, light}, from, {current, pids, sched_light(:stop, blink_timer)})
  end

  ## -----------------------------------------------------------------------------------------------
  ##  blink light
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:blink, light}, _from, {state_light, state_pids, :no_blink}) do
    pids =
      state_pids
      |> turn_off(state_light)

    log_action("blink", light)
    {:reply, {:ok, light}, {light, pids, sched_light(:on)}}
  end

  def handle_call({:blink, light}, from, {current, pids, blink_timer}) do
    handle_call({:blink, light}, from, {current, pids, sched_light(:stop, blink_timer)})
  end

  ## -----------------------------------------------------------------------------------------------
  ##  light status
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:status, light}, _from, {_current, pids, :no_blink} = state) do
    status = light_status(pids, light)
    {:reply, {:ok, status}, state}
  end

  def handle_call({:status, light}, _from, {current, pids, _blink} = state) do
    case light == current do
      true -> {:reply, {:ok, "blinking"}, state}
      _ -> {:reply, {:ok, light_status(pids, light)}, state}
    end
  end

  ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##
  ##  Allowing these calls is a purposeful mistake
  ##
  ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ## -----------------------------------------------------------------------------------------------
  ##  light on
  ##    - this call fails to turn the current light off or stop the blink timer
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:on, light}, _from, {_light, state_pids, blink}) do
    pids = turn_on(state_pids, light)
    log_action("on", light)
    {:reply, {:ok, "on"}, {light, pids, blink}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  light off
  ##    - this call fails to stop the blink timer
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:off, light}, _from, {_light, state_pids, blink}) do
    pids = turn_off(state_pids, light)
    log_action("off", light)
    {:reply, {:ok, "off"}, {light, pids, blink}}
  end

  ## ===============================================================================================
  ##
  ##  Info messages
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  blink lights on and off
  ## -----------------------------------------------------------------------------------------------
  def handle_info(:on, {light, state_pids, _blink}) do
    pids = turn_on(state_pids, light)
    {:noreply, {light, pids, sched_light(:off)}}
  end

  def handle_info(:off, {light, state_pids, _blink}) do
    pids = turn_off(state_pids, light)
    {:noreply, {light, pids, sched_light(:on)}}
  end

  ## ===============================================================================================
  ##
  ##  Cast messages
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  log action (debug output for host only)
  ## -----------------------------------------------------------------------------------------------
  def handle_cast({:log_action, action, light}, state) do
    status = lights_status(state)
    require Logger
    Logger.info("#{action} #{light}: #{inspect(status)}")
    {:noreply, state}
  end

  ## ===============================================================================================
  ##
  ## Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  turn light on
  ## -----------------------------------------------------------------------------------------------
  defp turn_on(pids, light) do
    turn_on(@target, pids, light)
  end

  defp turn_on("host", pids, light) do
    pids |> Map.put(light, "on")
  end

  defp turn_on(_target, pids, light) do
    GPIO.write(pids[light], @on)
    pids
  end

  ## -----------------------------------------------------------------------------------------------
  ##  turn light off
  ## -----------------------------------------------------------------------------------------------
  defp turn_off(pids, light) do
    turn_off(@target, pids, light)
  end

  defp turn_off("host", pids, light) do
    pids |> Map.put(light, "off")
  end

  defp turn_off(_target, pids, light) do
    GPIO.write(pids[light], @off)
    pids
  end

  ## -----------------------------------------------------------------------------------------------
  ##  status of lights
  ## -----------------------------------------------------------------------------------------------
  defp lights_status({light, pids, :no_blink}) do
    red = light_status(pids, :red)
    yellow = light_status(pids, :yellow)
    green = light_status(pids, :green)
    %{light: light, red: red, yellow: yellow, green: green}
  end

  defp lights_status({light, pids, _blink}) do
    lights_status({light, pids, :no_blink}) |> Map.put(light, "blinking")
  end

  ## -----------------------------------------------------------------------------------------------
  ##  status of single light
  ## -----------------------------------------------------------------------------------------------
  defp light_status(pids, light) do
    light_status(@target, pids, light)
  end

  defp light_status("host", pids, light) do
    pids[light]
  end

  defp light_status(_target, pids, light) do
    case GPIO.read(pids[light]) do
      @off -> "off"
      @on -> "on"
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Return timer to turn light on/off in @blink milliseconds
  ## -----------------------------------------------------------------------------------------------
  defp sched_light(:on) do
    :erlang.send_after(@blink, self(), :on)
  end

  defp sched_light(:off) do
    :erlang.send_after(@blink, self(), :off)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Cancel timer
  ## -----------------------------------------------------------------------------------------------
  defp sched_light(:stop, blink_timer) do
    :erlang.cancel_timer(blink_timer)
    :no_blink
  end
end
