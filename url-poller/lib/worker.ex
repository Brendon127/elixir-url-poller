defmodule UrlPoller.Worker do
  use GenServer

  defstruct [:urls, :interval, :name, :id]

  # Client API
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def get_info(pid) do
    GenServer.call(pid, :get_info)
  end

  def update_config(pid, new_config) do
    GenServer.call(pid, {:update_config, new_config})
  end

  # Server Callbacks
  def init(config) do
    schedule_poll(config[:interval])
    state = struct(__MODULE__, config)
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, %{id: state.id, name: state.name, urls: state.urls, interval: state.interval}, state}
  end

  def handle_call({:update_config, new_config}, _from, state) do
    updated_state = struct(state, new_config)
    {:reply, :ok, updated_state}
  end

  def handle_info(:poll, state) do
    Enum.each(state.urls, fn url -> 
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: status}} ->
          IO.puts("[#{state.name}] #{url} - Status: #{status}")
        {:error, reason} ->
          IO.puts("[#{state.name}] #{url} - Error: #{inspect(reason)}")
      end
    end)
    schedule_poll(state.interval)
    {:noreply, state}
  end

  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end
end
