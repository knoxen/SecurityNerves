defmodule StopLight.Elli.ChildSpec do
  @target System.get_env("MIX_TARGET")

  def spec(intf) do
    %{
      id: Elli,
      start: {:elli, :start_link, [opts(intf)]}
    }
  end

  defp opts(:http) do
    elli = Application.get_env(:stop_light, :elli)

    [
      {:callback, :elli_middleware},
      {:callback_args, [{:mods, elli[:stack]}]},
      {:port, elli[:port]},
      {:min_acceptors, 5},
      {:name, {:local, :elli}}
    ]
  end

  defp opts(:https) do
    # opts(:http)
    [
      :ssl,
      pem(:key),
      pem(:cert)
    ] ++ opts(:http)
  end

  defp pem(:key), do: {:keyfile, pem_path(:key)}
  defp pem(:cert), do: {:certfile, pem_path(:cert)}

  defp pem_path(type) do
    pem_file = Application.get_env(:stop_light, :pem_file)

    pem_file[:path]
    |> Keyword.fetch!(
      @target
      |> case do
        "host" -> :host
        _ -> :device
      end
    )
    |> Path.join(pem_file[type])
  end
end
