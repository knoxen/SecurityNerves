defmodule StopLight.Elli.Responder do
  @moduledoc false

  require Logger

  ## ===============================================================================================
  ##
  ##  Elli response
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Send elli format response
  ## -----------------------------------------------------------------------------------------------
  def respond({:error, reason}) do
    Logger.warn("Bad Request: #{reason}")
    {400, resp_headers(:text), "Bad Request"}
  end

  def respond({:forbidden, reason}) do
    Logger.warn("Forbidden: #{reason}")
    {403, resp_headers(:text), "Forbidden"}
  end

  def respond({:not_allowed, reason}) do
    Logger.warn("Not allowed: #{reason}")
    {405, resp_headers(:text), "Not Allowed"}
  end

  def respond({type, body}) do
    {:ok, resp_headers(type), body}
  end

  ## -----------------------------------------------------------------------------------------------
  ##
  ##  Respond JSON
  ##
  ## -----------------------------------------------------------------------------------------------
  def respond_json(kvs) when is_list(kvs) do
    json_resp = List.foldl(kvs, %{}, fn {k, v}, map -> Map.put(map, k, v) end)
    {:ok, body} = Poison.encode(json_resp)
    respond({:json, body})
  end

  def respond_json(map) when is_map(map) do
    {:ok, body} = Poison.encode(map)
    respond({:json, body})
  end

  ## -----------------------------------------------------------------------------------------------
  ##
  ##  Response headers per content type
  ##
  ## -----------------------------------------------------------------------------------------------
  defp resp_headers(:json) do
    resp_headers("application/json")
  end

  defp resp_headers(:text) do
    resp_headers("text/plain")
  end

  defp resp_headers(content_type) do
    [{"Server", "StopNet Elli/0.10.0"}, {"Content-Type", content_type}]
  end
end
