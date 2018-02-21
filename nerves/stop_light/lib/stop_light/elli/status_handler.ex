defmodule StopLight.Elli.StatusHandler do
  @moduledoc false

  @behaviour :elli_handler

  require :elli_request, as: Request

  import StopLight.Elli.Responder

  alias StopLight.Login.Credentials
  alias StopLight.Login.Manager, as: Login
  alias StopLight.DevicePairing, as: Pairing

  @device_ready "ready"
  @device_pairing "pairing"
  @device_blocked "blocked"

  ## ===============================================================================================
  ##
  ##  Elli Behaviour
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Handle request
  ## -----------------------------------------------------------------------------------------------
  def handle(req, _args) do
    req
    |> Request.method()
    |> case do
      :GET ->
        req
        |> Request.path()
        |> case do
          ["device", "status"] ->
            device_status()

          _ ->
            device_ready()
        end

      :POST ->
        req
        |> Request.path()
        |> case do
          ["pair"] ->
            device_pairing()

          _ ->
            device_ready()
        end

      _ ->
        device_ready()
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Handle event
  ## -----------------------------------------------------------------------------------------------
  def handle_event(_event, _data, _args) do
    :ok
  end

  ## ===============================================================================================
  ##
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Device status
  ## -----------------------------------------------------------------------------------------------
  defp device_status do
    logged_in(Login.logged_in?())
  end

  defp logged_in(true), do: respond_json([{"status", @device_ready}])
  defp logged_in(false), do: credentials_exist(Credentials.exists?())

  defp credentials_exist(true), do: respond_json([{"status", @device_ready}])
  defp credentials_exist(false), do: pairing_active(Pairing.active?())

  defp pairing_active(true), do: respond_json([{"status", @device_pairing}])
  defp pairing_active(false), do: respond_json([{"status", @device_blocked}])

  ## -----------------------------------------------------------------------------------------------
  ##  Device ready
  ## -----------------------------------------------------------------------------------------------
  defp device_ready, do: allow_if(Login.logged_in?() or Credentials.exists?())

  ## -----------------------------------------------------------------------------------------------
  ##  Device pairing
  ## -----------------------------------------------------------------------------------------------
  defp device_pairing, do: allow_if(Pairing.active?())

  ## -----------------------------------------------------------------------------------------------
  ##  
  ## -----------------------------------------------------------------------------------------------
  defp allow_if(ok) do
    if ok do
      :ignore
    else
      respond({:not_allowed, "Action not allowed"})
    end
  end
end
