defmodule MiApp.Controller do
  use MiAppWeb, :controller

  def index(conn, _params) do
    version = Ordo.version()

    render(conn, "index.html", version: version)
  end
end
