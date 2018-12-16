defmodule Day06 do
  def input() do
    "day06_input.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [x, y] = String.split(line, ", ", trim: true)
      {String.to_integer(x), String.to_integer(y)}
    end)
  end

  def part1() do
    coordinates = input()

    coordinate_to_name =
      coordinates
      |> Enum.with_index(?A)
      |> Enum.map(fn {coordinate, id} -> {coordinate, to_string([id])} end)
      |> Enum.into(%{})

    {min_x, min_y, max_x, max_y} = bounding_area(coordinates)

    proximity_map =
      for x <- min_x..max_x,
          y <- min_y..max_y,
          into: %{},
          do: {{x, y}, coordinate_to_name[closest_coordinate({x, y}, coordinates)] || "."}

    # prints proximity map
    # min_y..max_y
    # |> Enum.map(fn y ->
    #   min_x..max_x
    #   |> Enum.map(fn x -> proximity_map[{x, y}] end)
    #   |> Enum.join()
    # end)
    # |> Enum.join("\n")
    # |> IO.puts()

    border_coordinates = border_coordinates(min_x, min_y, max_x, max_y)

    infinite_areas =
      border_coordinates
      |> Enum.map(&proximity_map[&1])
      |> Enum.into(MapSet.new())

    proximity_map
    |> Enum.reject(fn {_coordinate, area} -> MapSet.member?(infinite_areas, area) end)
    |> Enum.reduce(%{}, fn {_coordinate, area}, acc ->
      Map.update(acc, area, 1, &(&1 + 1))
    end)
    |> Map.values()
    |> Enum.max()
  end

  def bounding_area(coordinates) do
    Enum.reduce(coordinates, {1000, 1000, 0, 0}, fn {x, y}, {min_x, min_y, max_x, max_y} ->
      {min(min_x, x), min(min_y, y), max(max_x, x), max(max_y, y)}
    end)
  end

  def border_coordinates(min_x, min_y, max_x, max_y) do
    List.flatten(
      for(x <- min_x..max_x, do: [{x, min_y}, {x, max_y}]) ++
        for(y <- (min_y + 1)..(max_y - 1), do: [{min_x, y}, {max_x, y}])
    )
  end

  def closest_coordinate(map_coordinate, coordinates) do
    distances = Enum.map(coordinates, &{&1, distance(map_coordinate, &1)})

    {closest, min_distance} = Enum.min_by(distances, fn {_coordinate, distance} -> distance end)

    closest_count =
      distances
      |> Enum.filter(fn {_coordinate, distance} -> distance == min_distance end)
      |> length()

    if closest_count == 1 do
      closest
    else
      nil
    end
  end

  def part2() do
    coordinates = input()
    {min_x, min_y, max_x, max_y} = bounding_area(coordinates)

    # Checked manually: for all the border coordinates, the total distance is > 10 000.
    distances =
      for x <- min_x..max_x,
          y <- min_y..max_y,
          do: total_distance({x, y}, coordinates)

    Enum.count(distances, &(&1 < 10_000))
  end

  def total_distance(map_coordinate, coordinates) do
    coordinates
    |> Enum.map(&distance(map_coordinate, &1))
    |> Enum.sum()
  end

  def distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end
end
