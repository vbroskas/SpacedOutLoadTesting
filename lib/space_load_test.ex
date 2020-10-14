defmodule SpaceLoadTest do
  @moduledoc """
  for this test to work I needed to deactivate the user verification token in SpaceWeb.UserSocket, and add user_id to the socket
  params!
  """
  use GenServer
  require Logger

  # @socket_opts [
  #   url:
  #     "ws://localhost:4000/socket/websocket?token=#{generate_user_id()}&user_id=#{
  #       generate_user_id()
  #     }&username=bob",
  #   reconnect_interval: 10_000
  # ]

  @connect_tries 200
  @connect_wait 500

  def start(opts) do
    GenServer.start(__MODULE__, [opts])
  end

  def init(_) do
    {:ok, %{connect_count: 0}, {:continue, []}}
  end

  def handle_continue([], state) do
    IO.puts("in handle continue")

    {:ok, socket} =
      PhoenixClient.Socket.start_link(
        url:
          "ws://localhost:4000/socket/websocket?token=#{generate_user_id()}&user_id=#{
            generate_user_id()
          }&username=bob"
      )

    send(self(), :connect_channel)
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_info(%{event: "new_interval"}, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "new_url"}, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "presence_diff"}, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "presence_state"}, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "countdown_tick"}, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "new_msg"}, state) do
    {:noreply, state}
  end

  def handle_info(:connect_channel, %{connect_count: count}) when count > @connect_tries do
    Logger.error("Channel connection failed after #{@connect_tries * @connect_wait}ms")
    {:stop, :connect_timeout}
  end

  def handle_info(:connect_channel, state = %{socket: socket, connect_count: count}) do
    if PhoenixClient.Socket.connected?(socket) do
      {:ok, _response, channel} =
        PhoenixClient.Channel.join(
          socket,
          "space:25"
        )

      state = Map.put(state, :channel, channel)

      {:noreply, state}
    else
      Process.send_after(self(), :connect_channel, @connect_wait)
      {:noreply, %{state | connect_count: count + 1}}
    end
  end

  @id_length 20
  defp generate_user_id() do
    :crypto.strong_rand_bytes(@id_length)
    |> Base.encode64()
    |> binary_part(0, @id_length)
  end

  # defp generate_token(id, opts \\ []) do
  #   salt = Keyword.get(opts, :salt, "salt identifier")
  #   Phoenix.Token.sign(SpaceWeb.Endpoint, salt, id)
  # end
end
