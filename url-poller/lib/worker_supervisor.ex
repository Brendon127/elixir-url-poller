defmodule UrlPoller.WorkerSupervisor do
  use DynamicSupervisor

  def start_link({:ok, desired_state}) do
    Registry.start_link(keys: :unique, name: UrlPoller.WorkerRegistry)
    DynamicSupervisor.start_link(__MODULE__, desired_state, name: __MODULE__)
  end

  # DynamicSupervisor Init
  def init(_initial_state) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Client API
  def reconcile(desired_state) when is_list(desired_state) do
    validated_state = Enum.map(desired_state, &validate_config/1)
    current_workers = list_workers_with_info()
    reconcile_workers(validated_state, current_workers)
  end

  # Reconcilliation logic
  defp reconcile_workers(desired_state, current_workers) do
    current_map = Map.new(current_workers, fn {pid, info} -> {info.id, {pid, info}} end)
    desired_map = Map.new(desired_state, fn config -> {config[:id], config} end)

    current_ids = Map.keys(current_map)
    desired_ids = Map.keys(desired_map)

    Enum.each(current_ids -- desired_ids, fn id ->
      {pid, _} = current_map[id]
      DynamicSupervisor.terminate_child(__MODULE__, pid)
      Registry.unregister(UrlPoller.WorkerRegistry, id)
    end)

    Enum.each(desired_state, fn config -> 
      case Map.get(current_map, config[:id]) do
         {pid, current_info} -> 
            if different_config?(config, current_info) do
              UrlPoller.Worker.update_config(pid, config)
            end
          nil -> 
            spec = {UrlPoller.Worker, config}
            {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
            Registry.register(UrlPoller.WorkerRegistry, config[:id], pid)
      end
    end)
  end

  defp different_config?(desired, current) do
    desired[:urls] != current[:urls] || desired[:interval] != current[:interval] || desired[:name] != current[:name]
  end

  defp validate_config(config) do
    required = [:id, :name, :urls, :interval]
    case Enum.all?(required, &Keyword.has_key?(config, &1)) do
      true -> 
        if is_list(config[:urls]) and is_integer(config[:interval]) and config[:interval] > 0 do
          config
        else
          raise "Invalid config values: #{inspect(config)}"
        end
      false -> 
        raise "Missing required fields in config: #{inspect(config)}"
    end
  end

  def list_workers_with_info do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.filter(fn {_, pid, _, _} -> is_pid(pid) end)
    |> Enum.map(fn {_, pid, _, _} -> 
      info = UrlPoller.Worker.get_info(pid)
      {pid, info}
    end)
  end

  def list_workers do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _} -> pid end)
    |> Enum.filter(&is_pid/1)
  end

  def get_worker_pid(id) do
    case Registry.lookup(UrlPoller.WorkerRegistry, id) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

end
