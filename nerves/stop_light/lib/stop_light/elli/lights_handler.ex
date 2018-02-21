defmodule StopLight.Elli.LightsHandler do
  @moduledoc false

  @behaviour :elli_handler

  require :elli_request, as: Request

  import StopLight.Elli.Responder

  alias StopLight.Lights

  ## ===============================================================================================
  ##
  ##  Elli Behaviour
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Handle request
  ## -----------------------------------------------------------------------------------------------
  def handle(req, _args) do
    path = Request.path(req)

    req
    |> Request.method()
    |> case do
      :GET ->
        handle_get(path, req)

      :POST ->
        handle_post(path, req)

      method ->
        respond({:error, "Method not supported: #{inspect(method)}"})
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
  ##  GET requests
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Route /status
  ## -----------------------------------------------------------------------------------------------
  defp handle_get(["status"], _req) do
    {:ok, status} = light(:status)
    respond_json([{"status", status}])
  end

  ## -----------------------------------------------------------------------------------------------
  ##   Get route not allowed
  ## -----------------------------------------------------------------------------------------------
  defp handle_get(_path, req) do
    raw_path = Request.raw_path(req)
    respond({:error, "GET path not supported: #{raw_path}"})
  end

  ## ===============================================================================================
  ##
  ##  POST requests
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##   Handle /light
  ## -----------------------------------------------------------------------------------------------
  defp handle_post(["light"], req) do
    req
    |> Request.body()
    |> Poison.decode!()
    |> parse_light
    |> case do
      {"switch", color} ->
        {:ok, switch} = light({:switch, color})
        respond_json([{"on", switch}])

      {"blink", color} ->
        {:ok, blink} = light({:blink, color})
        respond_json([{"blink", blink}])

      {"status", color} ->
        {:ok, status} = light({:status, color})
        respond_json([{color, status}])

      {"on", color} ->
        {:ok, status} = light({:on, color})
        respond_json([{color, status}])

      {"off", color} ->
        {:ok, status} = light({:off, color})
        respond_json([{color, status}])

      {:error, _} = error ->
        respond(error)

      {action, _color} ->
        respond({:error, "Unknown action: #{action}"})
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##   POST route not allowed
  ## -----------------------------------------------------------------------------------------------
  defp handle_post(_path, req) do
    raw_path = Request.raw_path(req)
    respond({:error, "POST path not supported: #{raw_path}"})
  end

  ## ===============================================================================================
  ##
  ##  Parse light JSON
  ##
  ## ===============================================================================================
  defp parse_light(%{"light" => color, "action" => action}), do: {action, String.to_atom(color)}
  defp parse_light(%{"light" => _}), do: {:error, "Missing action"}
  defp parse_light(%{"action" => _}), do: {:error, "Missing light color"}
  defp parse_light(_), do: {:error, "Invalid JSON"}

  ## ===============================================================================================
  ##
  ##  Light actions
  ##
  ## ===============================================================================================
  defp light({:switch, color}) do
    Lights.switch(color)
  end

  defp light({:blink, color}) do
    Lights.blink(color)
  end

  defp light({:status, color}) do
    Lights.status(color)
  end

  defp light(:status) do
    Lights.status()
  end

  ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##
  ##  Exposing these matches is a purposeful mistake
  ##
  ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  defp light({:on, color}) do
    Lights.on(color)
  end

  defp light({:off, color}) do
    Lights.off(color)
  end
end
