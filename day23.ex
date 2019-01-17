defmodule Day23 do
  @doc """
  Parses the description of nanobots.

      iex> Day23.parse_nanobots(\"""
      ...> pos=<0,0,0>, r=4
      ...> pos=<1,0,0>, r=1
      ...> pos=<4,0,0>, r=3
      ...> \""")
      [{0, 0, 0, 4}, {1, 0, 0, 1}, {4, 0, 0, 3}]
  """
  def parse_nanobots(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      line
      |> String.split(["pos=<", ",", ">, r="], trim: true)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end)
  end

  @doc """
  Finds the strongest nanobot.

      iex> Day23.find_strongest([
      ...>   {0, 0, 0, 4},
      ...>   {1, 0, 0, 1},
      ...>   {4, 0, 0, 3}
      ...> ])
      {0, 0, 0, 4}
  """
  def find_strongest(nanobots) do
    Enum.max_by(nanobots, fn {_x, _y, _z, range} -> range end)
  end

  @doc """
  Returns the distance between nanobots.

      iex> Day23.distance({0, 0, 0}, {4, 0, 0})
      4

      iex> Day23.distance({0, 0, 0}, {0, 2, 0})
      2

      iex> Day23.distance({0, 0, 0}, {0, 5, 0})
      5
  """
  def distance({x1, y1, z1}, {x2, y2, z2}) do
    abs(x2 - x1) + abs(y2 - y1) + abs(z2 - z1)
  end

  @doc """
  Returns true if the coordinate or nanobot is in the range of the nanobot.

      iex> Day23.in_range?({0, 0, 0, 4}, {4, 0, 0})
      true

      iex> Day23.in_range?({0, 0, 0, 4}, {0, 5, 0})
      false

      iex> Day23.in_range?({0, 0, 0, 4}, {4, 0, 0, 3})
      true

      iex> Day23.in_range?({0, 0, 0, 4}, {0, 5, 0, 3})
      false
  """
  def in_range?({x1, y1, z1, range1}, {x2, y2, z2}) do
    distance({x1, y1, z1}, {x2, y2, z2}) <= range1
  end

  def in_range?({x1, y1, z1, range1}, {x2, y2, z2, _range2}) do
    distance({x1, y1, z1}, {x2, y2, z2}) <= range1
  end

  @doc """
  Returns the count of nanobots in range of the specified one.

      iex> Day23.nanobots_in_range({0, 0, 0, 4}, [
      ...>   {0, 0, 0, 4},
      ...>   {1, 0, 0, 1},
      ...>   {4, 0, 0, 3},
      ...>   {0, 2, 0, 1},
      ...>   {0, 5, 0, 3},
      ...>   {0, 0, 3, 1},
      ...>   {1, 1, 1, 1},
      ...>   {1, 1, 2, 1},
      ...>   {1, 3, 1, 1}
      ...> ])
      7
  """
  def nanobots_in_range(nanobot, nanobots) do
    Enum.count(nanobots, fn n -> in_range?(nanobot, n) end)
  end

  def input() do
    "day23_input.txt"
    |> File.read!()
    |> parse_nanobots()
  end

  def part1() do
    nanobots = input()

    nanobots
    |> find_strongest()
    |> nanobots_in_range(nanobots)
  end

  @doc """
  Returns the bounding box for the nanobots positions, not including the ranges.
  """
  def bounding_box(nanobots) do
    {min_x, max_x} =
      nanobots
      |> Enum.map(fn {x, _y, _z, _r} -> x end)
      |> Enum.min_max()

    {min_y, max_y} =
      nanobots
      |> Enum.map(fn {_x, y, _z, _r} -> y end)
      |> Enum.min_max()

    {min_z, max_z} =
      nanobots
      |> Enum.map(fn {_x, _y, z, _r} -> z end)
      |> Enum.min_max()

    {{min_x, min_y, min_z}, {max_x, max_y, max_z}}
  end

  @doc """
  Returns the upper bound of the max amount of nanobots in range for any coordinate in the box.
  For the unit box returns the exact count.
  """
  def upper_bound_count({{x, y, z}, {x, y, z}}, nanobots) do
    Enum.count(nanobots, fn nanobot -> in_range?(nanobot, {x, y, z}) end)
  end

  def upper_bound_count({{min_x, min_y, min_z}, {max_x, max_y, max_z}}, nanobots) do
    dx2 = div(max_x - min_x, 2) + 1
    dy2 = div(max_y - min_y, 2) + 1
    dz2 = div(max_z - min_z, 2) + 1

    box_r = dx2 + dy2 + dz2

    mid_x = min_x + dx2
    mid_y = min_y + dy2
    mid_z = min_z + dz2

    Enum.count(nanobots, fn {x, y, z, r} ->
      distance({x, y, z}, {mid_x, mid_y, mid_z}) <= r + box_r
    end)
  end

  @doc """
  Splits the box along the longest dimension into two smaller ones that cover the same area.

      iex> Day23.split_box({{-10, -10, -10}, {10, 10, 10}})
      [
        {{-10, -10, -10}, {0, 10, 10}},
        {{1, -10, -10}, {10, 10, 10}},
      ]

      iex> Day23.split_box({{2, 3, 5}, {2, 3, 6}})
      [{{2, 3, 5}, {2, 3, 5}}, {{2, 3, 6}, {2, 3, 6}}]

      iex> Day23.split_box({{2, 3, 4}, {2, 3, 4}})
      []
  """
  def split_box({{x, y, z}, {x, y, z}}) do
    []
  end

  def split_box({{min_x, min_y, min_z}, {max_x, max_y, max_z}}) do
    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z

    cond do
      dx >= dy && dx >= dz ->
        mid_x = min_x + div(dx, 2)

        [
          {{min_x, min_y, min_z}, {mid_x, max_y, max_z}},
          {{mid_x + 1, min_y, min_z}, {max_x, max_y, max_z}}
        ]

      dy >= dx && dy >= dz ->
        mid_y = min_y + div(dy, 2)

        [
          {{min_x, min_y, min_z}, {max_x, mid_y, max_z}},
          {{min_x, mid_y + 1, min_z}, {max_x, max_y, max_z}}
        ]

      true ->
        mid_z = min_z + div(dz, 2)

        [
          {{min_x, min_y, min_z}, {max_x, max_y, mid_z}},
          {{min_x, min_y, mid_z + 1}, {max_x, max_y, max_z}}
        ]
    end
  end

  @doc """
  Returns true if the box is a unit (1x1x1).

      iex> Day23.unit_box?({{2, -2, 3}, {2, -2, 3}})
      true

      iex> Day23.unit_box?({{1, 1, 1}, {2, 3, 4}})
      false
  """
  def unit_box?({{x, y, z}, {x, y, z}}), do: true
  def unit_box?(_box), do: false

  @doc """
  Returns the distance from the origin for unit box or "infinity" otherwise.
  """
  def box_distance({{x, y, z}, {x, y, z}}), do: distance({x, y, z}, {0, 0, 0})
  def box_distance(_box), do: 1_000_000_000

  @doc """
  Finds the coordinate that is in range of the largest number of nanobots
  and is closest from the origin.

      iex> Day23.find_best_coordinate([
      ...>   {10, 12, 12, 2},
      ...>   {12, 14, 12, 2},
      ...>   {16, 12, 12, 4},
      ...>   {14, 14, 14, 6},
      ...>   {50, 50, 50, 200},
      ...>   {10, 10, 10, 5},
      ...> ])
      {{12, 12, 12}, 5, 36}
  """
  def find_best_coordinate(nanobots) do
    bounding_box = bounding_box(nanobots)

    length(nanobots)..1
    |> Stream.map(fn guess ->
      find_best_coordinate([bounding_box], {nil, guess, 1_000_000_000}, 1, nanobots)
    end)
    |> Enum.find(fn solution -> solution != :no_solution end)
  end

  def find_best_coordinate([], {nil, _count, _distance}, _queue_length, _nanobots) do
    :no_solution
  end

  def find_best_coordinate(
        [],
        {{{x, y, z}, {x, y, z}}, count, distance},
        _queue_length,
        _nanobots
      ) do
    {{x, y, z}, count, distance}
  end

  def find_best_coordinate(
        [box | rest],
        {_best_box, best_count, best_distance} = best,
        queue_size,
        nanobots
      ) do
    # We don't need the exact number, upper bound is enough to discard a box.
    # For unit boxes, the upper_bound_count returns the exact value.
    count = upper_bound_count(box, nanobots)
    unit_box = unit_box?(box)

    # IO.puts("#{inspect(best_box)}, c: #{best_count}, d: #{best_distance}, q: #{queue_size}")

    cond do
      unit_box ->
        distance = box_distance(box)

        next_best =
          if {count, -distance} > {best_count, -best_distance} do
            {box, count, distance}
          else
            best
          end

        find_best_coordinate(rest, next_best, queue_size - 1, nanobots)

      count < best_count ->
        find_best_coordinate(rest, best, queue_size - 1, nanobots)

      true ->
        [box1, box2] = split_box(box)
        find_best_coordinate([box1, box2 | rest], best, queue_size - 1 + 2, nanobots)
    end
  end
end
