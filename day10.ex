defmodule Day10 do
  @doc """
  Parses the star descriptions.

    iex> Day10.parse_stars([
    ...>   "position=<-42601, -53357> velocity=< 4,  5>",
    ...>   "position=< 10946,  43042> velocity=<-1, -4>",
    ...>   "position=< 21657,  32332> velocity=<-2, -3>",
    ...> ])
    [{-42601, -53357, 4, 5}, {10946, 43042, -1, -4}, {21657, 32332, -2, -3}]
  """
  def parse_stars(lines) do
    Enum.map(lines, fn line ->
      [x, y, vx, vy] =
        line
        |> String.split(["position", "velocity", "=", ",", " ", "<", ">"], trim: true)
        |> Enum.map(&String.to_integer/1)

      {x, y, vx, vy}
    end)
  end

  def example() do
    """
    position=< 9,  1> velocity=< 0,  2>
    position=< 7,  0> velocity=<-1,  0>
    position=< 3, -2> velocity=<-1,  1>
    position=< 6, 10> velocity=<-2, -1>
    position=< 2, -4> velocity=< 2,  2>
    position=<-6, 10> velocity=< 2, -2>
    position=< 1,  8> velocity=< 1, -1>
    position=< 1,  7> velocity=< 1,  0>
    position=<-3, 11> velocity=< 1, -2>
    position=< 7,  6> velocity=<-1, -1>
    position=<-2,  3> velocity=< 1,  0>
    position=<-4,  3> velocity=< 2,  0>
    position=<10, -3> velocity=<-1,  1>
    position=< 5, 11> velocity=< 1, -2>
    position=< 4,  7> velocity=< 0, -1>
    position=< 8, -2> velocity=< 0,  1>
    position=<15,  0> velocity=<-2,  0>
    position=< 1,  6> velocity=< 1,  0>
    position=< 8,  9> velocity=< 0, -1>
    position=< 3,  3> velocity=<-1,  1>
    position=< 0,  5> velocity=< 0, -1>
    position=<-2,  2> velocity=< 2,  0>
    position=< 5, -2> velocity=< 1,  2>
    position=< 1,  4> velocity=< 2,  1>
    position=<-2,  7> velocity=< 2, -2>
    position=< 3,  6> velocity=<-1, -1>
    position=< 5,  0> velocity=< 1,  0>
    position=<-6,  0> velocity=< 2,  0>
    position=< 5,  9> velocity=< 1, -2>
    position=<14,  7> velocity=<-2,  0>
    position=<-3,  6> velocity=< 2, -1>
    """
    |> String.split("\n", trim: true)
    |> parse_stars()
  end

  def input() do
    "day10_input.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> parse_stars()
  end

  @doc """
  Finds the bounding box of the stars.

      iex> Day10.bounding_box([{1, 2, -1, 2}, {3, 7, 2, 1}])
      {1, 2, 3, 7}
  """
  def bounding_box(stars) do
    Enum.reduce(stars, {nil, nil, nil, nil}, fn {x, y, _vx, _vy}, {min_x, min_y, max_x, max_y} ->
      {min(min_x || x, x), min(min_y || y, y), max(max_x || x, x), max(max_y || y, y)}
    end)
  end

  @doc """
  Moves the stars according to their velocity.

      iex> Day10.move_stars([{0, 0, 2, -3}, {2, 4, 3, 0}])
      [{2, -3, 2, -3}, {5, 4, 3, 0}]
  """
  def move_stars(stars) do
    Enum.map(stars, fn {x, y, vx, vy} -> {x + vx, y + vy, vx, vy} end)
  end

  @doc """
  Moves the stars until they are aligned (until they occupy minimum vertical space).
  """
  def move_stars_till_aligned(stars) do
    move_stars_till_aligned(stars, 0, 10_000_000)
  end

  defp move_stars_till_aligned(stars, time_passed, min_height) do
    moved_stars = move_stars(stars)
    {_min_x, min_y, _max_x, max_y} = bounding_box(moved_stars)
    new_height = max_y - min_y + 1

    if new_height < min_height do
      move_stars_till_aligned(moved_stars, time_passed + 1, new_height)
    else
      {stars, time_passed}
    end
  end

  @doc """
  Prints the stars.
  """
  def print_stars(stars) do
    positions =
      stars
      |> Enum.map(fn {x, y, _vx, _vy} -> {x, y} end)
      |> Enum.into(MapSet.new())

    {min_x, min_y, max_x, max_y} = bounding_box(stars)

    Enum.each(min_y..max_y, fn y ->
      Enum.map(min_x..max_x, fn x ->
        if {x, y} in positions do
          "*"
        else
          " "
        end
      end)
      |> Enum.join()
      |> IO.puts()
    end)
  end

  def part1() do
    {stars, _elapsed} =
      input()
      |> move_stars_till_aligned()

    print_stars(stars)
  end

  def part2() do
    {_stars, elapsed} =
      input()
      |> move_stars_till_aligned()

    elapsed
  end
end
