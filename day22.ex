defmodule Day22 do
  @doc """
  Generates the cave with the specified depth from the mouth till the target.

      iex> cave = Day22.generate_cave(510, {10, 10})
      iex> cave[{0, 0}]
      {0, 510, :rocky}
      iex> cave[{1, 0}]
      {16807, 17317, :wet}
      iex> cave[{0, 1}]
      {48271, 8415, :rocky}
      iex> cave[{1, 1}]
      {145722555, 1805, :narrow}
      iex> cave[{10, 10}]
      {0, 510, :rocky}
  """
  def generate_cave(depth, target, size \\ nil) do
    {size_x, size_y} = size || target

    Enum.reduce(0..size_y, %{}, fn y, cave ->
      Enum.reduce(0..size_x, cave, fn x, cave ->
        Map.put(cave, {x, y}, calculate_location({x, y}, depth, target, cave))
      end)
    end)
  end

  defp calculate_location(location, depth, {target_x, target_y}, cave) do
    geologic_index =
      case location do
        {0, 0} ->
          0

        {^target_x, ^target_y} ->
          0

        {x, 0} ->
          x * 16807

        {0, y} ->
          y * 48271

        {x, y} ->
          {_, erosion_level_left, _} = cave[{x - 1, y}]
          {_, erosion_level_top, _} = cave[{x, y - 1}]
          erosion_level_left * erosion_level_top
      end

    erosion_level = rem(geologic_index + depth, 20183)

    region_type =
      case rem(erosion_level, 3) do
        0 -> :rocky
        1 -> :wet
        2 -> :narrow
      end

    {geologic_index, erosion_level, region_type}
  end

  @doc """
  Calculates the lisk level for the cave.

      iex> cave = Day22.generate_cave(510, {10, 10})
      iex> Day22.risk_level(cave)
      114
  """
  def risk_level(cave) do
    cave
    |> Enum.map(fn {_location, {_geologic_index, _erosion_level, region_type}} ->
      case region_type do
        :rocky -> 0
        :wet -> 1
        :narrow -> 2
      end
    end)
    |> Enum.sum()
  end

  def part1() do
    generate_cave(3198, {12, 757}) |> risk_level()
  end

  @doc """
  Finds the shortest path from the cave mouth to the target.

      iex> Day22.shortest_path(510, {10, 10})
      45
  """
  def shortest_path(depth, {target_x, target_y} = target) do
    # Extend the search area by 4. Figured it out by experimenting.
    {size_x, size_y} = {target_x * 4, target_y * 4}
    cave = generate_cave(depth, target, {size_x, size_y})

    locations =
      for x <- 0..size_x,
          y <- 0..size_y,
          gear <- [:torch, :climbing_gear, :neither],
          do: {{x, y}, gear}

    # For each location we need to track the shortest distance with a specific
    # gear to find the actual shortest path. For example, taking a longer next
    # step with climbing gear may pay off better than taking a shorter next
    # step with torch.
    distances =
      for(location <- locations, into: %{}, do: {location, 1_000_000})
      |> Map.merge(%{
        {{0, 0}, :torch} => 0,
        {{0, 0}, :climbing_gear} => 7,
        {{0, 0}, :neither} => 1_000_000
      })

    unvisited = MapSet.new(locations) |> MapSet.delete({{0, 0}, :torch})
    distances = shortest_path(cave, {{0, 0}, :torch}, distances, MapSet.new(), unvisited, target)
    distances[{target, :torch}]
  end

  defp shortest_path(_cave, {target, :torch}, distances, _queue, _unvisited, target) do
    distances
  end

  defp shortest_path(cave, current, distances, queue, unvisited, target) do
    {current_location, _current_gear} = current

    {distances, queue} =
      current_location
      |> adjecent_locations(cave)
      |> Enum.flat_map(fn adjecent_location ->
        [
          {adjecent_location, :torch},
          {adjecent_location, :climbing_gear},
          {adjecent_location, :neither}
        ]
      end)
      |> Enum.filter(fn neighbour -> neighbour in unvisited end)
      |> Enum.reduce({distances, queue}, fn neighbour, {distances, queue} ->
        best_distance_so_far = distances[neighbour]
        distance_through_current = distances[current] + distance(current, neighbour, cave)

        if distance_through_current < best_distance_so_far do
          {
            Map.put(distances, neighbour, distance_through_current),
            MapSet.put(queue, neighbour)
          }
        else
          {distances, queue}
        end
      end)

    # A priority queue would bring even more performance here, but a set is enough
    # since the "queue" is not pre-filled with all the possible location, but grown as
    # the pathfinding progresses
    next = Enum.min_by(queue, fn item -> distances[item] end)

    shortest_path(
      cave,
      next,
      distances,
      MapSet.delete(queue, next),
      MapSet.delete(unvisited, next),
      target
    )
  end

  defp adjecent_locations({x, y}, cave) do
    [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
    |> Enum.filter(fn location -> Map.has_key?(cave, location) end)
  end

  defp distance({from_location, from_gear}, {to_location, to_gear}, cave) do
    {_, _, from_region_type} = cave[from_location]
    {_, _, to_region_type} = cave[to_location]

    if can_use?(from_region_type, to_gear) and can_use?(to_region_type, to_gear) do
      1 + switch_time(from_gear, to_gear)
    else
      1_000_000
    end
  end

  defp can_use?(region_type, gear) do
    valid_gear =
      case region_type do
        :rocky -> [:torch, :climbing_gear]
        :wet -> [:climbing_gear, :neither]
        :narrow -> [:torch, :neither]
      end

    gear in valid_gear
  end

  defp switch_time(from_gear, to_gear) do
    if from_gear == to_gear do
      0
    else
      7
    end
  end

  def part2() do
    shortest_path(3198, {12, 757})
  end
end
