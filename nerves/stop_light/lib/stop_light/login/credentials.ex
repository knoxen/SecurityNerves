defmodule StopLight.Login.Credentials do
  @target System.get_env("MIX_TARGET")

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Credentials exist?
  ## -----------------------------------------------------------------------------------------------
  def exists? do
    cred_file() |> File.exists?()
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Read credentials
  ## -----------------------------------------------------------------------------------------------
  def read do
    cred_file()
    |> File.read()
    |> case do
      {:ok, credentials} -> credentials
      {:error, _} -> nil
    end
  end

  def remove do
    cred_file() |> File.rm()
  end

  def write(credentials) do
    cred_file() |> File.write!(credentials)
  end

  defp cred_file do
    cred_file = Application.get_env(:stop_light, :cred_file)

    cred_file[:path]
    |> Keyword.fetch!(
      @target
      |> case do
        "host" -> :host
        _ -> :device
      end
    )
    |> Path.join(cred_file[:name])
  end
end
