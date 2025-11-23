defmodule Tbm.App do
  use Application

  def start(_type, _args) do
    children = [
      {Tbm.Display, []},
      {Plug.Cowboy, scheme: :http, plug: Tbm.Api.Router, port: 8080},
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end