defmodule Server do

  use Application

  def start(_type, _args) do
    ChatServer.Supervisor.start_link
  end

end