defmodule AndyWorldWeb.GMLive do
  @moduledoc """
    The dynamic visualization of a robot's generative model.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()

    {:ok,
     assign(socket,
       all_robot_names: [],
       selected_robot_name: nil,
       all_gm_names: [],
       selected_gm_name: nil,
       round_status: :not_started,
       perceptions: [],
       predictions_in: [],
       prediction_errors_out: [],
       beliefs: [],
       coas: []
     )}
  end

  @impl true
  def handle_event("robot_selected", %{"value" => robot_name_s}, socket) do
    Logger.warn("ROBOT SELECTED #{robot_name_s}")
    robot_name = String.to_existing_atom(robot_name_s)
    all_gm_names = all_gm_names(robot_name)

    gm_name =
      if socket.assigns.selected_gm_name in all_gm_names,
        do: socket.assigns.selected_gm_name,
        else: List.first(all_gm_names)

    updated_socket =
      assign(socket,
        selected_robot_name: robot_name,
        all_gm_names: all_gm_names,
        # TODO - grab the current state of the gm's current round
        selected_gm_name: gm_name,
        round_status: :unknown,
        predictions_in: [],
        perceptions: [],
        prediction_errors_out: [],
        beliefs: [],
        coas: []
      )

    {:noreply, updated_socket}
  end

  def handle_event("gm_selected", %{"value" => gm_name_s}, socket) do
    Logger.warn("GM SELECTED #{gm_name_s}")
    gm_name = String.to_existing_atom(gm_name_s)
    # TODO - grab the current state of the gm's current round
    updated_socket =
      assign(socket,
        selected_gm_name: gm_name,
        round_status: :unknown,
        predictions_in: [],
        perceptions: [],
        prediction_errors_out: [],
        beliefs: [],
        coas: []
      )

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:robot_placed, %{robot: robot}}, socket) do
    all_robot_names = [robot.name | socket.assigns.all_robot_names]
    selected_robot_name = socket.assigns.selected_robot_name
    selected_gm_name = socket.assigns.selected_gm_name

    robot_name =
      if selected_robot_name == nil, do: List.first(all_robot_names), else: selected_robot_name

    gm_names =
      if selected_gm_name == nil, do: all_gm_names(robot_name), else: socket.assigns.all_gm_names

    gm_name = if selected_gm_name == nil, do: List.first(gm_names), else: selected_gm_name

    {:noreply,
     assign(socket,
       all_robot_names: all_robot_names,
       selected_robot_name: robot_name,
       selected_gm_name: gm_name,
       all_gm_names: gm_names
     )}
  end

  @impl true
  def handle_info(
        {:robot_event,
         %{
           robot: robot,
           event: {:predictions, %{gm_name: gm_name, list: list}}
         }},
        socket
      ) do
    if socket.assigns.selected_robot_name == robot.name and
         gm_name == socket.assigns.selected_gm_name do
      {:noreply, assign(socket, predictions_in: list)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {:robot_event,
         %{
           robot: robot,
           event: {:perceptions, %{gm_name: gm_name, list: list}}
         }},
        socket
      ) do
    if socket.assigns.selected_robot_name == robot.name and
         gm_name == socket.assigns.selected_gm_name do
      {:noreply, assign(socket, perceptions: list)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {:robot_event,
         %{
           robot: robot,
           event: {:beliefs, %{gm_name: gm_name, list: list}}
         }},
        socket
      ) do
    if socket.assigns.selected_robot_name == robot.name and
         gm_name == socket.assigns.selected_gm_name do
      {:noreply, assign(socket, beliefs: list)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {:robot_event,
         %{
           robot: robot,
           event: {:prediction_error, %{value: %{belief: %{source: gm_name}}} = prediction_error}
         }},
        socket
      ) do
    if socket.assigns.selected_robot_name == robot.name and
         gm_name == socket.assigns.selected_gm_name do
      prediction_errors = socket.assigns.prediction_errors_out
      {:noreply, assign(socket, prediction_errors_out: [prediction_error | prediction_errors])}
    else
      {:noreply, socket}
    end
  end

  def handle_info({_topic, _payload}, socket) do
    # Logger.info("IGNORING #{inspect(topic)} with #{inspect(payload)}")
    {:noreply, socket}
  end

  ### PRIVATE

  defp tag_label(:prediction, :in), do: "prediction-in"
  defp tag_label(:prediction, :perception), do: "prediction"
  defp tag_label(:prediction_error, :perception), do: "prediction-error"
  defp tag_label(:prediction_error, :out), do: "prediction-error-out"

  defp tag_color(:prediction, :in), do: "is-primary"
  defp tag_color(:prediction, :perception), do: "is-warning"
  defp tag_color(:prediction_error, :perception), do: "is-danger"
  defp tag_color(:prediction_error, :out), do: "is-info"

  defp all_gm_names(robot_name) do
    gm_tree = AndyWorld.gm_tree(robot_name)
    Map.keys(gm_tree) |> Enum.sort()
  end

  defp option_selected(name, name), do: "selected=selected"
  defp option_selected(_name, _other), do: ""

  defp subscribe() do
    ~w(robot_placed robot_event)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

 end
