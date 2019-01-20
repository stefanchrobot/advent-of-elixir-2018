defmodule Day25 do
  @doc """
  Parses the points.

      iex> Day25.parse_points(\"""
      ...> -1,2,2,0
      ...> 0,0,2,-2
      ...> 0,0,0,-2
      ...> \""")
      [
        {-1, 2, 2, 0},
        {0, 0, 2, -2},
        {0, 0, 0, -2}
      ]
  """
  def parse_points(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      line
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end)
  end

  @doc """
  Returns the Manhattan distance between two points.

      iex> Day25.distance({0, 0, 0, 0}, {3, 0, 0, 0})
      3

      iex> Day25.distance({3, 0, 0, 0}, {0, 3, 0, 0})
      6
  """
  def distance({w1, x1, y1, z1}, {w2, x2, y2, z2}) do
    abs(w2 - w1) + abs(x2 - x1) + abs(y2 - y1) + abs(z2 - z1)
  end

  @doc """
  Returns true if the point belongs to the constellation.

      iex> Day25.belongs_to?({0, 0, 0, 6}, [{0, 0, 0, 0}, {0, 0, 0, 3}])
      true

      iex> Day25.belongs_to?({0, 0, 0, 9}, [{0, 0, 0, 0}, {0, 0, 0, 3}])
      false
  """
  def belongs_to?(point, constellation) do
    Enum.any?(constellation, fn other -> distance(point, other) <= 3 end)
  end

  @doc """
  Builds the constellations from points.
  """
  def build_constellations(points) do
    Enum.reduce(points, [], fn point, constellations ->
      {matching, non_matching} = Enum.split_with(constellations, &belongs_to?(point, &1))

      if matching == [] do
        [[point] | constellations]
      else
        new_constellation = [point | List.flatten(matching)]
        [new_constellation | non_matching]
      end
    end)
  end

  @doc """
  Returns the number of constellations formed by the points.

      iex> Day25.count_constellations([
      ...>   {-1, 2, 2, 0},
      ...>   {0, 0, 2, -2},
      ...>   {0, 0, 0, -2},
      ...>   {-1, 2, 0, 0},
      ...>   {-2, -2, -2, 2},
      ...>   {3, 0, 2, -1},
      ...>   {-1, 3, 2, 2},
      ...>   {-1, 0, -1, 0},
      ...>   {0, 2, 1, -2},
      ...>   {3, 0, 0, 0},
      ...> ])
      4
  """
  def count_constellations(points) do
    points
    |> build_constellations()
    |> Enum.count()
  end

  def input() do
    "day25_input.txt"
    |> File.read!()
    |> parse_points()
  end

  def part1() do
    input()
    |> count_constellations()
  end
end
