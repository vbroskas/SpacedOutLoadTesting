defmodule SpaceLoadTest.StartConnections do
  def start_connections(chunks \\ 4) do
    Enum.each(1..chunks, fn _ ->
      Enum.each(1..100, fn _ -> SpaceLoadTest.start([]) end)
      Process.sleep(100)
    end)
  end
end
