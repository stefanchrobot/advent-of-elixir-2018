defmodule Day18 do
  @doc """
  Parses the scanned area.

      iex> area = Day18.parse_area(\"""
      ...> .#.#...|#.
      ...> .....#|##|
      ...> .|..|...#.
      ...> ..|#.....#
      ...> #.#|||#|#|
      ...> \""")
      iex> area[{1, 1}]
      :open
      iex> area[{2, 3}]
      :trees
      iex> area[{6, 2}]
      :lumberyard
  """
  def parse_area(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.with_index(1)
    |> Enum.reduce(%{}, fn {line, y}, area ->
      line
      |> String.graphemes()
      |> Enum.with_index(1)
      |> Enum.reduce(area, fn {char, x}, area ->
        item =
          case char do
            "." -> :open
            "|" -> :trees
            "#" -> :lumberyard
          end

        Map.put(area, {x, y}, item)
      end)
    end)
  end

  @doc """
  Returns the bounding box of the area.

      iex> Day18.parse_area(\"""
      ...> .#.#
      ...> ....
      ...> .|..
      ...> \""") |> Day18.bounding_box()
      {1, 1, 4, 3}
  """
  def bounding_box(area) do
    {{{min_x, min_y}, _}, {{max_x, max_y}, _}} =
      Enum.min_max_by(area, fn {location, _item} -> location end)

    {min_x, min_y, max_x, max_y}
  end

  @doc """
  Converts the area to string.

      iex> Day18.parse_area(\"""
      ...> .#.#...|#.
      ...> .....#|##|
      ...> .|..|...#.
      ...> ..|#.....#
      ...> #.#|||#|#|
      ...> \""") |> Day18.format_area()
      \"""
      .#.#...|#.
      .....#|##|
      .|..|...#.
      ..|#.....#
      #.#|||#|#|
      \"""
  """
  def format_area(area, opts \\ [color?: false]) do
    color? = opts[:color?]
    {min_x, min_y, max_x, max_y} = bounding_box(area)

    for y <- min_y..max_y do
      for x <- min_x..max_x, into: "" do
        case area[{x, y}] do
          :open -> if color?, do: colored_text(".", 0, 0, 0), else: "."
          :trees -> if color?, do: colored_text("|", 0, 255, 0), else: "|"
          :lumberyard -> if color?, do: colored_text("#", 100, 50, 50), else: "#"
        end
      end
    end
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp colored_text(text, r, g, b) do
    "\x1b[38;2;#{r};#{g};#{b}m#{text}\x1b[0m"
  end

  @doc """
  Returns the adjecent locations.

      iex> Day18.adjecent({3, 5}) |> length()
      8
  """
  def adjecent({x, y}) do
    [
      {x - 1, y - 1},
      {x, y - 1},
      {x + 1, y - 1},
      {x - 1, y},
      {x + 1, y},
      {x - 1, y + 1},
      {x, y + 1},
      {x + 1, y + 1}
    ]
  end

  @doc """
  Returns the area after a single minute passes.

      iex> Day18.parse_area(\"""
      ...> .#.#...|#.
      ...> .....#|##|
      ...> .|..|...#.
      ...> ..|#.....#
      ...> #.#|||#|#|
      ...> ...#.||...
      ...> .|....|...
      ...> ||...#|.#|
      ...> |.||||..|.
      ...> ...#.|..|.
      ...> \""") |>
      ...> Day18.next_minute() |>
      ...> Day18.format_area()
      \"""
      .......##.
      ......|###
      .|..|...#.
      ..|#||...#
      ..##||.|#|
      ...#||||..
      ||...|||..
      |||||.||.|
      ||||||||||
      ....||..|.
      \"""
  """
  def next_minute(area) do
    {min_x, min_y, max_x, max_y} = bounding_box(area)

    for x <- min_x..max_x, y <- min_y..max_y, into: %{} do
      {{x, y}, next_value({x, y}, area)}
    end
  end

  defp next_value({x, y}, area) do
    adjecent =
      {x, y}
      |> adjecent()
      |> Enum.map(fn location -> area[location] end)

    case area[{x, y}] do
      :open ->
        if count(adjecent, :trees) >= 3 do
          :trees
        else
          :open
        end

      :trees ->
        if count(adjecent, :lumberyard) >= 3 do
          :lumberyard
        else
          :trees
        end

      :lumberyard ->
        if count(adjecent, :lumberyard) >= 1 and count(adjecent, :trees) >= 1 do
          :lumberyard
        else
          :open
        end
    end
  end

  defp count(items, item) do
    Enum.count(items, fn x -> x == item end)
  end

  def after_minutes(area, count) do
    Enum.reduce(1..count, area, fn _x, area -> next_minute(area) end)
  end

  @doc """
  Returns the resource value of the area.

      iex> Day18.parse_area(\"""
      ...> .||##.....
      ...> ||###.....
      ...> ||##......
      ...> |##.....##
      ...> |##.....##
      ...> |##....##|
      ...> ||##.####|
      ...> ||#####|||
      ...> ||||#|||||
      ...> ||||||||||
      ...> \""") |> Day18.resource_value()
      1147
  """
  def resource_value(area) do
    items = Map.values(area)
    trees_count = count(items, :trees)
    lumberyard_count = count(items, :lumberyard)
    trees_count * lumberyard_count
  end

  @doc """
  Returns the resource value after _n_ minutes.

      iex> Day18.parse_area(\"""
      ...> .#.#...|#.
      ...> .....#|##|
      ...> .|..|...#.
      ...> ..|#.....#
      ...> #.#|||#|#|
      ...> ...#.||...
      ...> .|....|...
      ...> ||...#|.#|
      ...> |.||||..|.
      ...> ...#.|..|.
      ...> \""") |> Day18.resource_value_after(10)
      1147
  """
  def resource_value_after(area, n) do
    area
    |> after_minutes(n)
    |> resource_value()
  end

  def input() do
    "day18_input.txt"
    |> File.read!()
    |> parse_area()
  end

  def part1() do
    input() |> resource_value_after(10)
  end

  def clear_screen() do
    IO.write([IO.ANSI.home(), IO.ANSI.clear()])
  end

  def animate(area) do
    Enum.reduce(1..1_000, area, fn _x, area ->
      clear_screen()
      area |> format_area(color?: true) |> IO.puts()
      Process.sleep(100)
      next_minute(area)
    end)
  end

  @doc """
  Returns the pair of minutes
  """
  def find_cycle(area) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.reduce_while(%{0 => area}, fn minute, areas ->
      area = next_minute(areas[minute - 1])

      case Enum.find(areas, fn {_prev_minute, prev_area} -> prev_area == area end) do
        nil -> {:cont, Map.put(areas, minute, area)}
        {prev_minute, _prev_area} -> {:halt, {prev_minute, minute}}
      end
    end)
  end

  @doc """
  Finds the resource value after _n_ minutes for big values assuming that
  there are relatively small cycles.
  """
  def resource_value_after_big_n(area, n) do
    {first, second} = find_cycle(area)
    minimum_minutes = minimum_minutes(first, second, n)
    resource_value_after(area, minimum_minutes)
  end

  @doc """
  Given a cycle in the area, calculates the minimum amount of minutes
  so that the area would be the same as if after _n_ minutes.

      iex> # _ _ _ C C c c C C c | c C C c c ...
      iex> Day18.minimum_minutes(4, 6, 10)
      4
  """
  def minimum_minutes(first, second, n) do
    cycle_length = second - first
    first + rem(n - first, cycle_length)
  end

  def part2() do
    input() |> resource_value_after_big_n(1_000_000_000)
  end
end
