defmodule AndyWorldWeb.ImageController do
  @moduledoc """
  Controller for obtaining images.
  """

  use Phoenix.Controller
  require Logger

  def get_gms_png(conn, %{"png_file" => png_file}) do
    respond_with_png(conn, png_file)
  end

  defp respond_with_png(conn, file_path) do
    put_resp_content_type(conn, "image/png")
    bytes = File.read!(file_path)
    File.rm(file_path)
    send_resp(conn, 200, bytes)
  end
end
