defmodule Tbm.Api do
  @spec search_stop_area(String.t()) :: Tbm.StopArea.t()
  def search_stop_area(filter) do
    case Tbm.Request.request(:get, "/places/stops/search", qs: %{query: filter}) do
      %Req.Response{status: 200, body: %{places: places}} ->
        Enum.map(places, &Tbm.StopArea.new/1)

      _ ->
        []
    end
  end

  @spec get_directions(Tbm.StopArea.t()) :: list(Tbm.Direction.t())
  def get_directions(%Tbm.StopArea{} = stop_area) do
    case Tbm.Request.request(:get, "/timetables/stops/#{stop_area.id}") do
      %Req.Response{status: 200, body: %{lineRoutePairs: lineRoutePairs}} ->
        Enum.map(lineRoutePairs, &Tbm.Direction.new/1)

      _ ->
        []
    end
  end

  @spec get_timetable(Tbm.StopArea.t(), Tbm.Direction.t()) :: Tbm.Timetable.t()
  def get_timetable(%Tbm.StopArea{} = stop_area, %Tbm.Direction{} = direction) do
    path = "/timetables/lines/#{direction.line.id}/routes/#{direction.route.id}/stops/#{stop_area.id}"

    case Tbm.Request.request(:get, path) do
      %Req.Response{status: 200, body: body} ->
        Tbm.Timetable.new(body)

      _ ->
        []
    end
  end
end
