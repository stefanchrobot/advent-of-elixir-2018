defmodule Day17 do
  @spring_location {500, 0}

  @doc """
  Parses the veins of clay.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> \""")
      [{495..495, 2..7}, {495..501, 7..7}, {501..501, 3..7}]
  """
  def parse_veins(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      line
      |> String.split(", ", trim: true)
      |> Enum.sort()
      |> Enum.map(&parse_range/1)
      |> List.to_tuple()
    end)
  end

  defp parse_range(range_str) do
    [_var_name, range] = String.split(range_str, "=")

    case String.split(range, "..") do
      [from] -> String.to_integer(from)..String.to_integer(from)
      [from, to] -> String.to_integer(from)..String.to_integer(to)
    end
  end

  @doc """
  Builds the slice of ground from the scanned veins of clay.

      iex> veins = Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""")
      iex> slice = Day17.build_slice(veins)
      iex> slice[{495, 2}]
      :clay
      iex> slice[{501, 7}]
      :clay
      iex> slice[{498, 5}]
      :sand
      iex> slice[{500, 0}]
      :spring
  """
  def build_slice(veins) do
    clay_squares =
      Enum.reduce(veins, [], fn {x_range, y_range}, squares ->
        for x <- x_range, y <- y_range, into: squares, do: {x, y}
      end)

    {{min_x, _}, {max_x, _}} = Enum.min_max_by(clay_squares, fn {x, _y} -> x end)
    {_, max_y} = Enum.max_by(clay_squares, fn {_x, y} -> y end)

    sand_slice =
      for x <- (min_x - 1)..(max_x + 1),
          y <- 0..(max_y + 1),
          into: %{},
          do: {{x, y}, :sand}

    Enum.reduce(clay_squares, sand_slice, fn square, slice -> Map.put(slice, square, :clay) end)
    |> Map.put(@spring_location, :spring)
  end

  @doc """
  Returns the bounding box of the area with clay.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""") |> Day17.build_slice() |> Day17.clay_bounding_box()
      {495, 1, 506, 13}
  """
  def clay_bounding_box(slice) do
    clay_squares =
      slice
      |> Enum.filter(fn {_location, value} -> value == :clay end)
      |> Enum.map(fn {location, _value} -> location end)

    {{min_x, _}, {max_x, _}} = Enum.min_max_by(clay_squares, fn {x, _y} -> x end)
    {{_, min_y}, {_, max_y}} = Enum.min_max_by(clay_squares, fn {_x, y} -> y end)

    {min_x, min_y, max_x, max_y}
  end

  @doc """
  Formats the slice of ground.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""") |> Day17.build_slice() |> Day17.format_slice()
      \"""
      ......+.......
      ............#.
      .#..#.......#.
      .#..#..#......
      .#..#..#......
      .#.....#......
      .#.....#......
      .#######......
      ..............
      ..............
      ....#.....#...
      ....#.....#...
      ....#.....#...
      ....#######...
      ..............
      \"""
  """
  def format_slice(slice) do
    {min_x, _min_y, max_x, max_y} = clay_bounding_box(slice)

    for y <- 0..(max_y + 1) do
      for x <- (min_x - 1)..(max_x + 1), into: "" do
        case slice[{x, y}] do
          :sand -> "."
          :clay -> "#"
          :water_flow -> "|"
          :water_rest -> "~"
          :spring -> "+"
        end
      end
    end
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  def inspect_slice(slice) do
    slice |> format_slice() |> IO.puts()
    slice
  end

  def dump_slice(slice) do
    File.write!("day17_output.txt", format_slice(slice))
    slice
  end

  @doc """
  Flows the water through the slice.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""") |> Day17.build_slice() |> Day17.flow_water() |> Day17.format_slice()
      \"""
      ......+.......
      ......|.....#.
      .#..#||||...#.
      .#..#~~#|.....
      .#..#~~#|.....
      .#~~~~~#|.....
      .#~~~~~#|.....
      .#######|.....
      ........|.....
      ...|||||||||..
      ...|#~~~~~#|..
      ...|#~~~~~#|..
      ...|#~~~~~#|..
      ...|#######|..
      ...|.......|..
      \"""
  """
  def flow_water(slice) do
    {_min_x, _min_y, _max_x, max_y} = clay_bounding_box(slice)
    flow_water(slice, [@spring_location], max_y + 1)
  end

  defp flow_water(slice, [], _max_y), do: slice

  # Flows the water down.
  defp flow_water(slice, [{x, y} | rest], max_y) do
    square = slice[{x, y}]
    square_below = slice[{x, y + 1}]

    cond do
      # The source has been filled with resting water from another source.
      square == :water_rest ->
        flow_water(slice, rest, max_y)

      # Stop from going to infinity.
      y == max_y ->
        flow_water(slice, rest, max_y)

      square_below == :sand ->
        slice
        |> Map.put({x, y + 1}, :water_flow)
        |> flow_water([{x, y + 1} | rest], max_y)

      # Two water sources fall into the same reservoir.
      square_below == :water_flow ->
        flow_water(slice, rest, max_y)

      square_below in [:clay, :water_rest] ->
        {new_sources, slice} = spread_water(slice, {x, y})
        flow_water(slice, new_sources ++ rest, max_y)
    end
  end

  @doc """
  Spreads the water on clay or resting water.

      iex> slice = \"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""" |> Day17.parse_veins() |> Day17.build_slice() |>
      ...> Map.put({500, 1}, :water_flow) |>
      ...> Map.put({500, 2}, :water_flow) |>
      ...> Map.put({500, 3}, :water_flow) |>
      ...> Map.put({500, 4}, :water_flow) |>
      ...> Map.put({500, 5}, :water_flow) |>
      ...> Map.put({500, 6}, :water_flow)
      iex> Day17.format_slice(slice)
      \"""
      ......+.......
      ......|.....#.
      .#..#.|.....#.
      .#..#.|#......
      .#..#.|#......
      .#....|#......
      .#....|#......
      .#######......
      ..............
      ..............
      ....#.....#...
      ....#.....#...
      ....#.....#...
      ....#######...
      ..............
      \"""
      iex> {new_sources, slice} = Day17.spread_water(slice, {500, 6})
      iex> Day17.format_slice(slice)
      \"""
      ......+.......
      ......|.....#.
      .#..#.|.....#.
      .#..#.|#......
      .#..#.|#......
      .#....|#......
      .#~~~~~#......
      .#######......
      ..............
      ..............
      ....#.....#...
      ....#.....#...
      ....#.....#...
      ....#######...
      ..............
      \"""
      iex> new_sources
      [{500, 5}]
      iex> {[{500, 4}], slice} = Day17.spread_water(slice, {500, 5})
      iex> {[{500, 3}], slice} = Day17.spread_water(slice, {500, 4})
      iex> {[{500, 2}], slice} = Day17.spread_water(slice, {500, 3})
      iex> Day17.format_slice(slice)
      \"""
      ......+.......
      ......|.....#.
      .#..#.|.....#.
      .#..#~~#......
      .#..#~~#......
      .#~~~~~#......
      .#~~~~~#......
      .#######......
      ..............
      ..............
      ....#.....#...
      ....#.....#...
      ....#.....#...
      ....#######...
      ..............
      \"""
      iex> {new_sources, slice} = Day17.spread_water(slice, {500, 2})
      iex> Day17.format_slice(slice)
      \"""
      ......+.......
      ......|.....#.
      .#..#||||...#.
      .#..#~~#......
      .#..#~~#......
      .#~~~~~#......
      .#~~~~~#......
      .#######......
      ..............
      ..............
      ....#.....#...
      ....#.....#...
      ....#.....#...
      ....#######...
      ..............
      \"""
      iex> new_sources
      [{502, 2}]

      iex> slice = \"""
      ...> x=497, y=2..5
      ...> x=503, y=2..5
      ...> y=5, x=498..502
      ...> y=3, x=500..500
      ...> \""" |> Day17.parse_veins() |> Day17.build_slice() |>
      ...> Map.put({500, 1}, :water_flow) |>
      ...> Map.put({500, 2}, :water_flow)
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#..|..#.
      .#..#..#.
      .#.....#.
      .#######.
      .........
      \"""
      iex> {new_sources, slice} = Day17.spread_water(slice, {500, 2})
      iex> new_sources
      [{499, 2}, {501, 2}]
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#.|||.#.
      .#..#..#.
      .#.....#.
      .#######.
      .........
      \"""
      iex> slice = slice |> Map.put({499, 2}, :water_flow) |> Map.put({499, 3}, :water_flow)
      iex> {[{499, 3}], slice} = Day17.spread_water(slice, {499, 4})
      iex> {[{499, 2}], slice} = Day17.spread_water(slice, {499, 3})
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#.|||.#.
      .#~~#..#.
      .#~~~~~#.
      .#######.
      .........
      \"""
      iex> {[{501, 2}], slice} = Day17.spread_water(slice, {499, 2})
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#||||.#.
      .#~~#..#.
      .#~~~~~#.
      .#######.
      .........
      \"""
      iex> slice = slice |> Map.put({501, 3}, :water_flow)
      iex> {[{501, 2}], slice} = Day17.spread_water(slice, {501, 3})
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#||||.#.
      .#~~#~~#.
      .#~~~~~#.
      .#######.
      .........
      \"""
      iex> {[{501, 1}], slice} = Day17.spread_water(slice, {501, 2})
      iex> Day17.format_slice(slice)
      \"""
      ....+....
      ....|....
      .#~~~~~#.
      .#~~#~~#.
      .#~~~~~#.
      .#######.
      .........
      \"""
  """
  def spread_water(slice, {x, y}) do
    {min_x, left_type} = spread_water(slice, x, y, -1)
    {max_x, right_type} = spread_water(slice, x, y, +1)

    filler =
      if left_type == :wall and right_type == :wall do
        :water_rest
      else
        :water_flow
      end

    updated_slice =
      Enum.reduce(min_x..max_x, slice, fn x, slice -> Map.put(slice, {x, y}, filler) end)

    new_sources =
      case {left_type, right_type} do
        {:wall, :wall} -> [{x, y - 1}]
        {:edge, :wall} -> [{min_x, y}]
        {:wall, :edge} -> [{max_x, y}]
        {:edge, :edge} -> [{min_x, y}, {max_x, y}]
      end

    {new_sources, updated_slice}
  end

  defp spread_water(slice, x, y, direction) do
    square_side = slice[{x + direction, y}]
    square_side_below = slice[{x + direction, y + 1}]

    cond do
      square_side == :clay ->
        {x, :wall}

      square_side in [:sand, :water_flow] and square_side_below == :sand ->
        {x + direction, :edge}

      square_side in [:sand, :water_flow] and square_side_below in [:clay, :water_rest] ->
        spread_water(slice, x + direction, y, direction)
    end
  end

  @doc """
  Calculates the number of square meters reachable by water.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""") |>
      ...> Day17.build_slice() |>
      ...> Day17.flow_water() |>
      ...> Day17.water_reach()
      57
  """
  def water_reach(slice) do
    {_min_x, min_y, _max_x, max_y} = clay_bounding_box(slice)

    Enum.count(slice, fn {{_x, y}, value} ->
      y in min_y..max_y and value in [:water_flow, :water_rest]
    end)
  end

  def example() do
    """
    x=495, y=2..7
    y=7, x=495..501
    x=501, y=3..7§
    x=506, y=1..2
    x=498, y=10..13
    x=504, y=10..13
    y=13, x=498..504
    """
    |> parse_veins()
    |> build_slice()
  end

  def input() do
    "day17_input.txt"
    |> File.read!()
    |> parse_veins()
    |> build_slice()
  end

  def part1() do
    input()
    |> flow_water()
    |> dump_slice()
    |> water_reach()
  end

  @doc """
  Calculates the amount of retained water.

      iex> Day17.parse_veins(\"""
      ...> x=495, y=2..7
      ...> y=7, x=495..501
      ...> x=501, y=3..7
      ...> x=498, y=2..4
      ...> x=506, y=1..2
      ...> x=498, y=10..13
      ...> x=504, y=10..13
      ...> y=13, x=498..504
      ...> \""") |>
      ...> Day17.build_slice() |>
      ...> Day17.flow_water() |>
      ...> Day17.water_retained()
      29
  """
  def water_retained(slice) do
    Enum.count(slice, fn {_, value} -> value == :water_rest end)
  end

  def part2() do
    input()
    |> flow_water()
    |> water_retained()
  end
end
