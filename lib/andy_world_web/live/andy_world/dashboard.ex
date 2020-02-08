defmodule AndyWorldWeb.Dashboard do
  @moduledoc """
    The top LiveView component
  """

  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
         <div>Andy World Dashboard</div>
    """
  end
end
