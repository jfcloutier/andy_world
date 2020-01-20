defmodule AndyWorldWeb.PageController do
  use AndyWorldWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
