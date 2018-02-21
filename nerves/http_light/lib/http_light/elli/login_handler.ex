defmodule HttpLight.Elli.LoginHandler do
  @moduledoc false

  @behaviour :elli_handler

  require :elli_request, as: Request

  alias StopLight.Login.Credentials
  alias StopLight.Login.Manager, as: Login
  alias StopLight.DevicePairing, as: Pairing

  import StopLight.Elli.Responder

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
      :POST ->
        case Request.path(req) do
          ["login"] ->
            login(req)

          ["pair"] ->
            pair(req)

          _ ->
            logged_in?()
        end

      _ ->
        logged_in?()
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Handle event
  ## -----------------------------------------------------------------------------------------------
  def handle_event(_event, _data, _args) do
    :ok
  end

  ## ===============================================================================================
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Login user
  ## -----------------------------------------------------------------------------------------------
  defp login(req) do
    req
    |> parse_credentials
    |> case do
      {:ok, credentials} ->
        if valid?(credentials) do
          Login.login(credentials["username"])
          respond_json(%{status: "ok"})
        else
          respond_json(%{status: "invalid"})
        end

      error ->
        respond(error)
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Device pairing
  ## -----------------------------------------------------------------------------------------------
  defp pair(req), do: req |> pair(Pairing.active?())

  defp pair(req, true) do
    req
    |> parse_credentials
    |> case do
      {:ok, credentials} ->
        Pairing.set_credentials(Poison.encode!(credentials))
        respond_json(%{status: "ok"})

      error ->
        respond(error)
    end
  end

  defp pair(_req, false), do: respond_json(%{status: "invalid"})

  ## -----------------------------------------------------------------------------------------------
  ##  Parse credentials from req
  ## -----------------------------------------------------------------------------------------------
  defp parse_credentials(req) do
    req
    |> Request.body()
    |> Poison.decode!()
    |> case do
      %{"username" => _, "password" => _} = credentials -> {:ok, credentials}
      %{"username" => _} -> {:error, "Missing password"}
      %{"password" => _} -> {:error, "Missing username"}
      _ -> {:error, "Invalid login JSON"}
    end
  end

  defp valid?(credentials) do
    if Credentials.exists?() do
      Credentials.read() |> Poison.decode!() |> Map.equal?(credentials)
    else
      false
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Is user logged in?
  ## -----------------------------------------------------------------------------------------------
  defp logged_in? do
    if Login.logged_in?() do
      Login.touch()
      :ignore
    else
      respond({:forbidden, "No user logged in"})
    end
  end
end
