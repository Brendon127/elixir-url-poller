defmodule UrlPoller.Application do
  use Application
  def start(_type, _args) do
    children = [
      {UrlPoller.WorkerSupervisor, {:ok, [[]]}}
    ]

    opts = [strategy: :one_for_one, name: UrlPoller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
