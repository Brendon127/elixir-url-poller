defmodule UrlPoller.MixProject do
  use Mix.Project

  def project do
    [
      app: :url_poller,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {UrlPoller.Application, []},
      extra_applications: [:logger, :wx, :observer, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"}
    ]
  end
end
