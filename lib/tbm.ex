defmodule Tbm.App do
  use Application

  def start(_type, _args) do
    children = [
      {Tbm.Display, []}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end