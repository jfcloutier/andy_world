defmodule AndyWorldWeb.GMGraphLive do
  @moduledoc """
    The dynamic visualization of GM tree.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  alias Graphvix.Graph
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()

    {:ok,
     assign(socket,
       robot_name: nil,
       # gm_id => gm_name
       selected_gm_names: %{},
       graph_png_file: nil
     )}
  end

  @impl true
  def handle_info({:gm_selected, %{id: id, robot_name: robot_name, gm_name: gm_name}}, socket) do
    selected_gm_names = socket.assigns.selected_gm_names
    updated_selected_names = Map.put(selected_gm_names, "#{id}", "#{gm_name}")
    graph_png_file = build_png(robot_name, Map.values(updated_selected_names))

    {:noreply,
     assign(socket,
       robot_name: robot_name,
       selected_gm_names: updated_selected_names,
       graph_png_file: graph_png_file
     )}
  end

  def handle_info({:showing_gms, gm_live_ids}, socket) do
    selected_gm_names = socket.assigns.selected_gm_names

    updated_selected_gm_names =
      Enum.reduce(
        gm_live_ids,
        %{},
        fn id, acc ->
          Map.put(acc, "#{id}", Map.get(selected_gm_names, "#{id}"))
        end
      )

    robot_name = socket.assigns.robot_name
    graph_png_file = build_png(robot_name, Map.values(updated_selected_gm_names))

    {:noreply,
     assign(socket, selected_gm_names: updated_selected_gm_names, graph_png_file: graph_png_file)}
  end

  defp subscribe() do
    ~w(robot_selected gm_selected showing_gms)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

  defp build_png(robot_name, highlighted) do
    gm_tree = AndyWorld.gm_tree(robot_name)
    gm_names = List.flatten(Map.keys(gm_tree) ++ Map.values(gm_tree)) |> Enum.uniq()

    {graph, vertex_ids} =
      Enum.reduce(
        gm_names,
        {Graph.new(width: 6, height: 4), %{}},
        fn gm_name, {acc_graph, acc_ids} ->
          color = if "#{gm_name}" in highlighted, do: "goldenrod2", else: "cornflowerblue"

          {acc_graph1, vertex_id} =
            Graph.add_vertex(acc_graph, "#{gm_name}",
              fontname: "helvetica bold",
              style: "filled",
              fillcolor: color,
              color: color,
              fontcolor: "white",
              shape: "box"
            )

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
                  Map.fetch!(vertex_ids, child),
                  color: "gray12"
                )

              acc1
            end
          )
        end
      )

    destination = "gm_graph_#{:os.system_time()}"
    Graph.compile(final_graph, destination)
    File.rm("#{destination}.dot")
    "#{destination}.png"
  end
end
