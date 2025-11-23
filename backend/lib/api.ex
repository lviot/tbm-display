defmodule Tbm.Api do
  defmodule Router do
    use Plug.Router

    plug :cors
    plug :match
    plug :dispatch

    defp cors(conn, _) do
      conn
      |> put_resp_header("Access-Control-Allow-Origin", "*")
      |> put_resp_header("Access-Control-Allow-Credentials", "true")
      |> put_resp_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
      |> put_resp_header("Access-Control-Allow-Headers", "Content-Type, Origin")
      |> put_resp_header("Access-Control-Expose-Headers", "location")
    end

    get "/api/v1/stop_areas" do
      conn = fetch_query_params(conn)

      conn.query_params
      |> Map.get("filter", "")
      |> then(&Tbm.Api.search_stop_area/1)
      |> struct_to_map()
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1))
    end

    get "/api/v1/stop_area/:stop_area_id/directions" do
      stop_area_id
      |> Tbm.Api.get_directions()
      |> struct_to_map()
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1))
    end

    post "/api/v1/stop_area/:stop_area_id/route/:route_id/set" do
      direction =
        stop_area_id
        |> Tbm.Api.get_directions()
        |> Enum.find(& &1.route.id === route_id)

      GenServer.cast(Tbm.Display, {:set_direction, stop_area_id, direction})

      send_resp(conn, 204, "")
    end

    def struct_to_map(term) when is_struct(term), do:
      term
      |> Map.from_struct()
      |> struct_to_map()
    def struct_to_map(term) when is_map(term), do:
      term
      |> Enum.map(fn {key, value} -> {key, struct_to_map(value)} end)
      |> Map.new()
    def struct_to_map(term) when is_list(term), do: Enum.map(term, &struct_to_map/1)
    def struct_to_map(term), do: term
  end

  @spec search_stop_area(String.t()) :: Tbm.StopArea.t()
  def search_stop_area(filter) do
    case Tbm.Request.request(:get, "/places/stops/search", qs: %{query: filter}) do
      %Req.Response{status: 200, body: %{places: places}} ->
        Enum.map(places, &Tbm.StopArea.new/1)

      _ ->
        []
    end
  end

  @spec get_directions(Tbm.StopArea.t() | String.t()) :: list(Tbm.Direction.t())
  def get_directions(%Tbm.StopArea{} = stop_area) do
    get_directions(stop_area.id)
  end
  def get_directions(stop_area_id) do
    case Tbm.Request.request(:get, "/timetables/stops/#{stop_area_id}") do
      %Req.Response{status: 200, body: %{lineRoutePairs: lineRoutePairs}} ->
        Enum.map(lineRoutePairs, &Tbm.Direction.new/1)

      _ ->
        []
    end
  end

  @spec get_timetable(Tbm.StopArea.t(), Tbm.Direction.t()) :: Tbm.Timetable.t()
  def get_timetable(%Tbm.StopArea{} = stop_area, %Tbm.Direction{} = direction) do
    get_timetable(direction.line.id, direction.route.id, stop_area.id)
  end
  @spec get_timetable(String.t(), String.t(), String.t()) :: Tbm.Timetable.t()
  def get_timetable(line_id, route_id, stop_area_id) do
    path = "/timetables/lines/#{line_id}/routes/#{route_id}/stops/#{stop_area_id}"

    case Tbm.Request.request(:get, path) do
      %Req.Response{status: 200, body: body} ->
        Tbm.Timetable.new(body)

      _ ->
        []
    end
  end
end
