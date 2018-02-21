defmodule StopLight.DevicePairing do
  @target System.get_env("MIX_TARGET")

  alias StopLight.Lights
  alias StopLight.Login.{Credentials, Manager}
  alias ElixirALE.GPIO

  ## ===============================================================================================
  ##
  ##  Module constants
  ##
  ## ===============================================================================================
  @pairing_pin 17
  @pairing_hold 1500
  @pairing_active 20000

  ## ===============================================================================================
  ##
  ##  Manage momentary button for device pairing (set/reset login credentials)
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
  ##
  ## -----------------------------------------------------------------------------------------------
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init
  ## -----------------------------------------------------------------------------------------------
  def init(_args) do
    {:ok, setup(@target)}
  end

  defp setup("host") do
    {"pairing_pid", :init}
  end

  defp setup(_target) do
    {:ok, pairing_pid} = GPIO.start_link(@pairing_pin, :input)
    GPIO.set_int(pairing_pid, :both)
    {pairing_pid, :init}
  end

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  def active?, do: GenServer.call(__MODULE__, :active?)

  def set_credentials(credentials),
    do: GenServer.call(__MODULE__, {:set_credentials, credentials})

  ## -----------------------------------------------------------------------------------------------
  ##  Simulate pairing activation (long press of the momentary button)
  ## -----------------------------------------------------------------------------------------------
  def pair, do: GenServer.call(__MODULE__, :pair)

  ## ===============================================================================================
  ##
  ##  Call messages
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Is pairing active?
  ## -----------------------------------------------------------------------------------------------
  def handle_call(:active?, _from, {_, :active, _} = state) do
    {:reply, true, state}
  end

  def handle_call(:active?, _from, state) do
    {:reply, false, state}
  end

  ## -----------------------------------------------------------------------------------------------
  ##
  ## -----------------------------------------------------------------------------------------------
  def handle_call({:set_credentials, credentials}, _from, {pairing_pid, :active, timer}) do
    :erlang.cancel_timer(timer)
    Credentials.write(credentials)
    Lights.blink(:green)
    {:reply, :ok, {pairing_pid, :ready}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Debug pairing
  ## -----------------------------------------------------------------------------------------------
  def handle_call(:pair, _from, {pairing_pid, _}) do
    timer = :erlang.send_after(10, self(), :activate)
    {:reply, :ok, {pairing_pid, :pressing, timer}}
  end
  
  ## -----------------------------------------------------------------------------------------------
  ##  No-op
  ## -----------------------------------------------------------------------------------------------
  def handle_call(_term, _from, state) do
    {:reply, :ignore, state}
  end

  ## ===============================================================================================
  ##
  ##  Info messages
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Any GPIO signal while in init state triggers ready state
  ## -----------------------------------------------------------------------------------------------
  def handle_info({:gpio_interrupt, @pairing_pin, _}, {pairing_pid, :init}) do
    {:noreply, {pairing_pid, :ready}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Button down and ready
  ##    Start pressing timer
  ## -----------------------------------------------------------------------------------------------
  def handle_info({:gpio_interrupt, @pairing_pin, :rising}, {pairing_pid, :ready}) do
    timer = :erlang.send_after(@pairing_hold, self(), :activate)
    {:noreply, {pairing_pid, :pressing, timer}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Button up and pressing
  ##    Cancel pressing timer
  ## -----------------------------------------------------------------------------------------------
  def handle_info({:gpio_interrupt, @pairing_pin, :falling}, {pairing_pid, :pressing, timer}) do
    :erlang.cancel_timer(timer)
    {:noreply, {pairing_pid, :ready}}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Ignore any other GPIO signal
  ## -----------------------------------------------------------------------------------------------
  def handle_info({:gpio_interrupt, @pairing_pin, _}, state) do
    {:noreply, state}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Activate
  ##    Pressing timer fires (i.e. button was held sufficiently long to trigger pairing)
  ## -----------------------------------------------------------------------------------------------
  def handle_info(:activate, {pairing_pid, :pressing, timer}) do
    :erlang.cancel_timer(timer)
    timer = :erlang.send_after(@pairing_active, self(), :deactivate)
    Credentials.remove()
    Manager.logout()
    Lights.blink(:yellow)
    {:noreply, {pairing_pid, :active, timer}}
  end

  def handle_info(:deactivate, state), do: {:noreply, state |> deactivate}

  ## -----------------------------------------------------------------------------------------------
  ##  No-op
  ## -----------------------------------------------------------------------------------------------
  def handle_info(_term, state) do
    {:noreply, state}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Deactivate received during an active timer
  ##    Cancel deativation.
  ## -----------------------------------------------------------------------------------------------
  defp deactivate({pairing_pid, :active, timer}) do
    :erlang.cancel_timer(timer)
    Lights.blink(:red)
    {pairing_pid, :ready}
  end

  defp deactivate(state), do: state
end
