defmodule RpiRgb do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif(~c"priv/rgbmatrix_nif", 0)
  end

  def led_matrix_create(_a, _b, _c) do
    raise "NIF led_matrix_create/3 not implemented"
  end

  def led_matrix_create_from_options(_a) do
    raise "NIF led_matrix_create_from_options/1 not implemented"
  end

  def led_matrix_create_from_options_and_rt_options(_a, _b) do
    raise "NIF led_matrix_create_from_options_and_rt_options/2 not implemented"
  end

  def create_options(_a) do
    raise "NIF create_options/1 not implemented"
  end

  def create_rt_options(_a) do
    raise "NIF create_rt_options/1 not implemented"
  end

  def led_matrix_create_offscreen_canvas(_a) do
    raise "NIF led_matrix_create_offscreen_canvas/1 not implemented"
  end

  def led_canvas_get_size(_a) do
    raise "NIF led_canvas_get_size/1 not implemented"
  end

  def led_canvas_set_pixel(_a, _b, _c, _d, _e, _f) do
    raise "NIF led_canvas_set_pixel/6 not implemented"
  end

  def led_canvas_clear(_a) do
    raise "NIF led_canvas_clear/1 not implemented"
  end

  def led_canvas_fill(_a, _b, _c, _d) do
    raise "NIF led_canvas_fill/4 not implemented"
  end

  def led_matrix_swap_on_vsync(_a, _b) do
    raise "NIF led_matrix_swap_on_vsync/2 not implemented"
  end

  def led_matrix_get_brightness(_a) do
    raise "NIF led_matrix_get_brightness/1 not implemented"
  end

  def led_matrix_set_brightness(_a, _b) do
    raise "NIF led_matrix_set_brightness/2 not implemented"
  end

  def load_font(_a) do
    raise "NIF load_font/1 not implemented"
  end

  def baseline_font(_a) do
    raise "NIF led_baseline_font/1 not implemented"
  end

  def height_font(_a) do
    raise "NIF leheight_font/1 not implemented"
  end

  def character_width_font(_a, _b) do
    raise "NIF led_matrix_character_width_font/2 not implemented"
  end

  def create_outline_font(_a) do
    raise "NIF led_matrixcreate_outline_font/1 not implemented"
  end

  def draw_text(_a, _b, _c, _d, _e, _f, _g, _h, _i) do
    raise "NIF draw_text/9 not implemented"
  end

  def vertical_draw_text(_a, _b, _c, _d, _e, _f, _g, _h, _i) do
    raise "NIF led_matrivertical_draw_text/9 not implemented"
  end

  def draw_circle(_a, _b, _c, _d, _e, _f, _g) do
    raise "NIF ledraw_circle/7 not implemented"
  end

  def draw_line(_a, _b, _c, _d, _e, _f, _g, _h) do
    raise "NIF draw_line/8 not implemented"
  end
end