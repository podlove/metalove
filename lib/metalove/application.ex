defmodule Metalove.Application do
  @moduledoc false

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Metalove.Worker.start_link(arg)
      {Metalove.Repository, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Metalove.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
