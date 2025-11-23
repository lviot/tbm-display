defmodule Tbm.Display do
  use GenServer

  # display
  @polling_rate :timer.seconds(30)
  @refresh_rate div(:timer.seconds(50), 1_000)
  # style
  @padding 2
  @logo_diameter 10

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {
      :ok,
      %{
        stop_area_id: Keyword.get(opts, :stop_area_id),
        direction: Keyword.get(opts, :direction),
        timetable: nil,
        display: nil,
        tick: 0,
      },
      {:continue, :init_display},
    }
  end

  @impl true
  def handle_continue(:init_display, state) do
    opts = RpiRgb.create_options([
      rows: 32,
      cols: 64,
      hardware_mapping: ~c"adafruit-hat",
    ])
    rt_opts = RpiRgb.create_rt_options([gpio_slowdown: 3])
    matrix = RpiRgb.led_matrix_create_from_options_and_rt_options(opts, rt_opts)

    Process.send_after(self(), :update_timetable, @polling_rate)
    Process.send_after(self(), :tick, @refresh_rate)

    {
      :noreply,
      %{state |
        display: %{
          matrix: matrix,
          canvas: RpiRgb.led_matrix_create_offscreen_canvas(matrix),
          font: RpiRgb.load_font(~c"priv/fonts/5x8.bdf"),
          logo_font: RpiRgb.load_font(~c"priv/fonts/6x10.bdf"),
          route_name_offset: 0,
        },
        tick: 0,
      },
      {:continue, :update_timetable},
    }
  end

  @impl true
  def handle_continue(
    :update_timetable,
    %{stop_area_id: stop_area_id, direction: direction} = state
  ) when is_binary(stop_area_id) do
    state =
      %{
        state |
        timetable: Tbm.Api.get_timetable(direction.line.id, direction.route.id, stop_area_id),
      }

    {:noreply, update_canvas(state)}
  end
  def handle_continue(:update_timetable, state), do: {:noreply, state}

  @impl true
  def handle_info(:update_timetable, state) do
    Process.send_after(self(), :update_timetable, @polling_rate)

    {:noreply, state, {:continue, :update_timetable}}
  end

  @impl true
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, @refresh_rate)

    {:noreply, update_canvas(%{state | tick: state.tick + 1})}
  end

  @impl true
  def handle_cast({:set_direction, stop_area_id, direction = %Tbm.Direction{}}, state) do
    {
      :noreply,
      %{
        state |
        stop_area_id: stop_area_id,
        direction: direction,
        display: %{
          state.display |
          route_name_offset: 0,
        },
        tick: 0,
      },
      {:continue, :update_timetable},
    }
  end

  defp update_canvas(%{
    timetable: %Tbm.Timetable{nextDepartures: []},
    direction: direction,
    display: display,
  } = state) do
    RpiRgb.led_canvas_clear(display.canvas)

    state =
      state
      |> draw_route_name(direction)
      |> draw_logo(direction)

    height = RpiRgb.height_font(display.font)
    {r, g, b} = Tbm.Color.white()

    RpiRgb.draw_text(
      display.canvas,
      display.font,
      @padding,
      @logo_diameter + @padding + (height + 1),
      r,
      g,
      b,
      ~c"HS",
      0
    )

    %{
      state |
      display: %{
        state.display |
        canvas: RpiRgb.led_matrix_swap_on_vsync(display.matrix, display.canvas),
      },
    }
  end
  defp update_canvas(%{
    timetable: %Tbm.Timetable{nextDepartures: [_ | _] = next_departures},
    direction: direction,
    display: display,
  } = state) do
    RpiRgb.led_canvas_clear(display.canvas)

    state =
      state
      |> draw_route_name(direction)
      |> draw_logo(direction)
      |> draw_next_departures(next_departures)

    %{
      state |
      display: %{
        state.display |
        canvas: RpiRgb.led_matrix_swap_on_vsync(display.matrix, display.canvas),
      },
    }
  end
  defp update_canvas(state), do: state

  defp draw_route_name(%{display: display} = state, direction) do
    baseline = RpiRgb.baseline_font(display.font)
    height = RpiRgb.height_font(display.font)
    white = Tbm.Color.white() |> Tbm.Color.to_map()
    black = Tbm.Color.black() |> Tbm.Color.to_map()

    # route name
    route_name = format_route_name(direction.route.name)
    {canvas_width, _} = RpiRgb.led_canvas_get_size(display.canvas)
    route_name_x_base = @logo_diameter + @padding * 2 + 1
    route_name_x = route_name_x_base - display.route_name_offset
    route_name_width =
      route_name
      |> String.to_charlist()
      |> Enum.map(&RpiRgb.character_width_font(display.font, &1))
      |> Enum.sum()

    route_name_offset =
      if route_name_x_base + route_name_width > canvas_width and state.tick > 25 do
        display.route_name_offset + 1
      else
        display.route_name_offset
      end

    {route_name_offset, tick} =
      if route_name_x + route_name_width < route_name_x_base do
        {0, 0}
      else
        {route_name_offset, state.tick}
      end

    RpiRgb.draw_text(display.canvas, display.font, route_name_x, baseline + @padding + 1, white.r, white.g, white.b, ~c"#{route_name}", 0)

    # clear logo area
    logo_area_x0 = 0
    logo_area_x1 = @logo_diameter + @padding * 2
    logo_area_y0 = @padding
    logo_area_y1 = height + @padding
    Enum.each(logo_area_x0..logo_area_x1, fn x ->
      Enum.each(logo_area_y0..logo_area_y1, fn y ->
        RpiRgb.led_canvas_set_pixel(display.canvas, x, y, black.r, black.g, black.b)
      end)
    end)

    %{
      state |
      tick: tick,
      display: %{
        state.display |
        route_name_offset: route_name_offset,
      },
    }
  end

  defp draw_logo(%{display: display} = state, direction) do
    radius = div(@logo_diameter, 2)
    white = Tbm.Color.white() |> Tbm.Color.to_map()
    circle_color =
      direction.line.style.color
      |> Tbm.Color.hex_to_rgb()
      |> Tbm.Color.to_map()

    RpiRgb.draw_circle(
      display.canvas,
      radius + @padding,
      radius + @padding,
      radius,
      circle_color.r,
      circle_color.g,
      circle_color.b
    )

    characters_width =
      direction.line.code
      |> String.to_charlist()
      |> Enum.map(&RpiRgb.character_width_font(display.logo_font, &1))
      |> Enum.sum()

    RpiRgb.draw_text(
      display.canvas,
      display.logo_font,
      @padding + @logo_diameter - characters_width - 1,
      @padding + @logo_diameter - 1,
      white.r, white.g, white.b, ~c"#{direction.line.code}", 0
    )

    state
  end

  defp draw_next_departures(%{display: display} = state, next_departures) do
    height = RpiRgb.height_font(display.font)
    now = DateTime.now!("Europe/Paris")
    {r, g, b} = Tbm.Color.white()

    next_departures
    |> Enum.reject(& Time.diff(&1.departure, now, :second) < 0)
    |> Enum.take(2)
    |> Enum.with_index()
    |> Enum.each(fn {departure, index} ->
      RpiRgb.draw_text(
        display.canvas,
        display.font,
        @padding,
        @logo_diameter + @padding + (height + 1) * (index + 1),
        r,
        g,
        b,
        printable_eta(departure, now),
        0
      )
    end)

    state
  end

  defp format_route_name(route_name) do
    sanitize_route_name(route_name)
  end

  defp sanitize_route_name(route_name) do
    route_name
    |> String.codepoints()
    |> Enum.map(&char_translation/1)
    |> Enum.join()
  end

  defp char_translation("é"), do: "e"
  defp char_translation("É"), do: "E"
  defp char_translation("è"), do: "e"
  defp char_translation("È"), do: "E"
  defp char_translation("à"), do: "a"
  defp char_translation("À"), do: "A"
  defp char_translation("ç"), do: "c"
  defp char_translation("Ç"), do: "C"
  defp char_translation(route_name), do: route_name

  defp printable_eta(%Tbm.Departure{departure: departure}, now) do
    seconds = Time.diff(departure, now, :second)
    minutes = Time.diff(departure, now, :minute)

    case {minutes, seconds} do
      {_, sec} when sec < 10 ->
        ~c"a quai"

      {min, _} when min < 2 ->
        ~c"proche"

      {min, _} ->
        formatted = String.pad_leading("#{min}", 2, "0")
        ~c"#{formatted} min"
    end
  end
end

defmodule Tbm.Color do
  def white(), do: {255, 255, 255}

  def black(), do: {0, 0, 0}

  def hex_to_rgb(<<"#", r :: binary-size(2), g :: binary-size(2), b :: binary-size(2)>>) do
    {
      String.to_integer(r, 16),
      String.to_integer(g, 16),
      String.to_integer(b, 16),
    }
  end

  def to_map({r, g, b}), do: %{r: r, g: g, b: b}
  def to_map(%{} = map), do: map

  def to_tuple(%{r: r, g: g, b: b}), do: {r, g, b}
  def to_tuple({_, _, _} = tuple), do: tuple
end

# [stop_area] = Tbm.Api.search_stop_area("Quinconces"); [direction|_] = Tbm.Api.get_directions(stop_area); GenServer.whereis(Tbm.Display) |> GenServer.cast({:set_direction, stop_area.id, direction})
