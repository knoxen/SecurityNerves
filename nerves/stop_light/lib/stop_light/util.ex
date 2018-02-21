defmodule StopLight.Util do
  def required_config(app, config) do
    case Application.get_env(app, config) do
      nil ->
        raise "#{app} missing configuration for #{config}"

      value ->
        value
    end
  end

  def dump_log(log) when is_atom(log) do
    dump_log(:erlang.atom_to_binary(log, :utf8))
  end

  def dump_log(log) when is_binary(log) do
    "/root/#{log}.log"
    |> File.open([:utf8, :read])
    |> case do
      {:ok, file} ->
        IO.binstream(file, :line)
        |> Stream.map(&IO.inspect(&1, limit: :infinity))
        |> Stream.run()

        File.close(file)

      {:error, reason} ->
        error_msg = :file.format_error(reason)
        "Error: #{error_msg}"
    end
  end

  def purge_log(log) when is_atom(log) do
    purge_log(:erlang.atom_to_binary(log, :utf8))
  end

  def purge_log(log) when is_binary(log) do
    "/root/#{log}.log"
    |> File.open([:write])
    |> case do
      {:ok, file} ->
        IO.binwrite(file, "")
        File.close(file)

      error ->
        error
    end
  end
end
