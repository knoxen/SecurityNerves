defmodule SrpcLight.SrpcHandler do
  @behaviour :srpc_handler

  alias StopLight.Login.Credentials
  alias StopLight.DevicePairing, as: Pairing

  ## ================================================================================================
  ##
  ##  Required
  ##
  ## ================================================================================================
  ## ------------------------------------------------------------------------------------------------
  ##  Conn ID
  ## ------------------------------------------------------------------------------------------------
  defmodule(ConnId, do: use(EntropyString, charset: EntropyString.CharSet.charset64()))
  def conn_id, do: ConnId.session_id()

  ## ------------------------------------------------------------------------------------------------
  ##  Exchange key/value
  ## ------------------------------------------------------------------------------------------------
  def put_exchange(conn_id, value) do
    :kncache.put(conn_id, value, :srpc_exch)
  end

  def get_exchange(conn_id) do
    :kncache.get(conn_id, :srpc_exch)
  end

  def delete_exchange(conn_id) do
    :kncache.delete(conn_id, :srpc_exch)
  end

  ## ------------------------------------------------------------------------------------------------
  ##  Connection key/value
  ## ------------------------------------------------------------------------------------------------
  def put_conn(conn_id, value) do
    :kncache.put(conn_id, value, :srpc_conn)
  end

  def get_conn(conn_id) do
    :kncache.get(conn_id, :srpc_conn)
  end

  def delete_conn(conn_id) do
    :kncache.delete(conn_id, :srpc_conn)
  end

  ## ------------------------------------------------------------------------------------------------
  ##  Registration key/value
  ##    There is only one "user" of the device (determined by pairing action)
  ## ------------------------------------------------------------------------------------------------
  def put_registration(_user_id, value) do
    value |> :erlang.term_to_binary() |> Pairing.set_credentials()
    :ok
  end

  def get_registration(_user_id) do
    if Credentials.exists?() do
      {:ok, Credentials.read() |> :erlang.binary_to_term()}
    else
      :undefined
    end
  end

  ## ================================================================================================
  ##
  ##  Optional
  ##
  ## ================================================================================================
  ## ------------------------------------------------------------------------------------------------
  ##
  ##  If the given nonce is pure, store it and return true; O/W return false
  ##
  ## ------------------------------------------------------------------------------------------------
  def nonce(nonce) do
    case :kncache.get(nonce, :srpc_nonce) do
      :undefined ->
        :kncache.put(nonce, :erlang.system_time(:seconds), :srpc_nonce)
        true

      _ ->
        false
    end
  end

  ## ------------------------------------------------------------------------------------------------
  ##
  ##  The tolerance for the age of requests. If 0, no check will be made.
  ##
  ## ------------------------------------------------------------------------------------------------
  def req_age_tolerance do
    Application.get_env(:srpc_elli, :req_age_tolerance, 0)
  end

  ## ------------------------------------------------------------------------------------------------
  ##
  ##  Handle registration data passed in request. Returned data is sent back in response.
  ##
  ## ------------------------------------------------------------------------------------------------
  def registration_data(user_id, reg_data) do
    :kncache.put(user_id, reg_data, :user_data)
    ""
  end
end
