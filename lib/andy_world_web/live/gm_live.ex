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
    all_robot_names = all_robot_names()
    selected_robot_name = default_selected_robot_name(all_robot_names)
    all_gm_names = all_gm_names(selected_robot_name)
    {:ok,
     assign(socket,
       all_robot_names: all_robot_names,
       selected_robot_name: selected_robot_name,
       all_gm_names: all_gm_names,
       selected_gm_name: default_selected_gm_name(all_gm_names),
       round_status: :not_started,
       perceptions: [],
       predictions_in: [],
       prediction_errors_out: [],
       beliefs: [],
       courses_of_action: []
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

    updated_assigns =
      reset_gm(robot_name, gm_name)
      |> Keyword.merge(
        selected_robot_name: robot_name,
        all_gm_names: all_gm_names,
        selected_gm_name: gm_name,
        round_status: :unknown
      )

    {:noreply, assign(socket, updated_assigns)}
  end

  def handle_event("gm_selected", %{"value" => gm_name_s}, socket) do
    Logger.warn("GM SELECTED #{gm_name_s}")
    gm_name = String.to_existing_atom(gm_name_s)
    robot_name = socket.assigns.selected_robot_name
    updated_assigns =
      reset_gm(robot_name, gm_name)
      |> Keyword.merge(
        selected_gm_name: gm_name,
        round_status: :unknown
      )

    {:noreply, assign(socket, updated_assigns)}
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
       event: {:courses_of_action, %{gm_name: gm_name, list: list}}
     }},
    socket
  ) do
if socket.assigns.selected_robot_name == robot.name and
     gm_name == socket.assigns.selected_gm_name do
  {:noreply, assign(socket, courses_of_action: list)}
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

  def handle_info(
        {:robot_event, %{robot: robot, event: {round_status, gm_name}}},
        socket
      )
      when round_status in [
             :round_initiating,
             :round_running,
             :round_completing,
             :round_completed
           ] do
    if socket.assigns.selected_robot_name == robot.name and
         gm_name == socket.assigns.selected_gm_name do
      updated_assigns =
        case round_status do
          :round_initiating ->
            reset_gm(robot.name, gm_name)

          _other ->
            []
        end
        |> Keyword.merge(round_status: round_status)

      {:noreply, assign(socket, updated_assigns)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({_topic, _payload}, socket) do
    # Logger.info("IGNORING #{inspect(topic)} with #{inspect(payload)}")
    {:noreply, socket}
  end

  ### PRIVATE

  defp all_robot_names() do
    for robot <- AndyWorld.robots(), do: robot.name
  end

  defp default_selected_robot_name([]), do: nil
  defp default_selected_robot_name([first | _]), do: first

  defp all_gm_names(nil), do: []
  defp all_gm_names(robot_name) do
    gm_tree = AndyWorld.gm_tree(robot_name)
    Map.keys(gm_tree) |> Enum.sort()
  end

  defp default_selected_gm_name([]), do: nil
  defp default_selected_gm_name([first | _]), do: first

  defp tag_label(:prediction, :in), do: "prediction in"
  defp tag_label(:prediction, :perception), do: "perception"
  defp tag_label(:prediction_error, :perception), do: "perception"
  defp tag_label(:prediction_error, :out), do: "prediction error out"
  defp tag_label(:course_of_action, _), do: "actions"

  defp tag_color(:prediction, :in, _), do: "is-primary is-light"
  defp tag_color(:prediction, :perception, _), do: "is-warning is-light"
  defp tag_color(:prediction_error, :perception, _), do: "is-danger is-light"
  defp tag_color(:prediction_error, :out, _), do: "is-danger is-light"
  defp tag_color(:belief, _, _), do: "is-success is-light"
  defp tag_color(:course_of_action, _, :round_completing), do: "is-success is-light"
  defp tag_color(:course_of_action, _, _), do: "is-light"

  defp round_status_label(:unknown), do: ("...")
 defp round_status_label(:not_started), do: ("not started")
  defp round_status_label(:round_initiating), do: ("initiating")
  defp round_status_label(:round_running), do: ("running")
  defp round_status_label(:round_completing), do: ("completing")
  defp round_status_label(:round_completed), do: ("completed")


  defp option_selected(name, name), do: "selected=selected"
  defp option_selected(_name, _other), do: ""

  defp subscribe() do
    ~w(robot_placed robot_event)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

  defp reset_gm(_robot_name, _gm_name) do
    # TODO - grab the current state of the gm's current round
    [predictions_in: [], perceptions: [], beliefs: [], prediction_errors_out: []]
  end
end
