defmodule AndyWorldWeb.ImageController do
  @moduledoc """
  Controller for obtaining images.
  """

  use Phoenix.Controller
  alias Graphvix.Graph
  require Logger

  def get_gms_png(conn, %{"robot_name" => robot_name, "selected_gms" => selected_gms}) do
    selected_gm_names = String.split(selected_gms, ":")

    build_png(robot_name, selected_gm_names)
    |> respond_with_png(conn)
  end

  defp build_png(robot_name, selected_gm_names) do
    Logger.warn("Building GM tree for robot #{inspect robot_name} with selected #{inspect selected_gm_names}")
    gm_tree = AndyWorld.gm_tree(String.to_existing_atom(robot_name))
    gm_names = List.flatten(Map.keys(gm_tree) ++ Map.values(gm_tree)) |> Enum.uniq()

    {graph, vertex_ids} =
      Enum.reduce(
        gm_names,
        {Graph.new(), %{}},
        fn gm_name, {acc_graph, acc_ids} ->
          color = if "#{gm_name}" in selected_gm_names, do: "red", else: "blue"

          {acc_graph1, vertex_id} =
            Graph.add_vertex(acc_graph, "#{gm_name}", color: color, shape: "box")

          acc_ids1 = Map.put(acc_ids, gm_name, vertex_id)
          {acc_graph1, acc_ids1}
        end
      )

    final_graph =
      Enum.reduce(
        gm_names,
        graph,
        fn gm_name, acc_graph ->
          children = Map.get(gm_tree, gm_name, [])

          Enum.reduce(
            children,
            acc_graph,
            fn child, acc ->
              {acc1, _edge_id} =
                Graph.add_edge(
                  acc,
                  Map.fetch!(vertex_ids, gm_name),
                  Map.fetch!(vertex_ids, child)
                )

              acc1
            end
          )
        end
      )
      Graph.compile(final_graph, "gm_tree")
      "gm_tree.png"
  end

  defp respond_with_png(file_path, conn) do
    put_resp_content_type(conn, "image/png")
    bytes = File.read!(file_path)
    send_resp(conn, 200, bytes)
  end
end
