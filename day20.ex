defmodule Day20 do
  @doc """
  Parses the routes regex.

      iex> Day20.parse_routes("^WNE$")
      [:w, :n, :e]

      iex> Day20.parse_routes("^N(E|W)N$")
      [:n, [[:e], [:w]], :n]

      iex> Day20.parse_routes("^ENWWW(NEEE|SSE(EE|N))$")
      [
        :e,
        :n,
        :w,
        :w,
        :w,
        [
          [:n, :e, :e, :e],
          [
            :s,
            :s,
            :e,
            [
              [:e, :e],
              [:n]
            ]
          ]
        ]
      ]

      iex> Day20.parse_routes("^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$")
      [
        :e,
        :s,
        :s,
        :w,
        :w,
        :n,
        [
          [:e],
          [
            :n,
            :n,
            :e,
            :n,
            :n,
            [
              [
                :e,
                :e,
                :s,
                :s,
                [
                  [:w, :n, :s, :e],
                  []
                ],
                :s,
                :s,
                :s
              ],
              [
                :w,
                :w,
                :w,
                :s,
                :s,
                :s,
                :s,
                :e,
                [
                  [:s, :w],
                  [:n, :n, :n, :e]
                ]
              ]
            ]
          ]
        ]
      ]
  """
  # Grammar:
  #   routes :: ^ route $
  #   route :: N route |
  #            E route |
  #            S route |
  #            W route |
  #            \( branches \) |
  #            ''
  #   branches :: route (\| branches)*
  def parse_routes(string) do
    <<"^", rest::binary>> = string
    {route, "$"} = parse_route(rest)
    route
  end

  defp parse_route(string), do: parse_route(string, [])

  defp parse_route(<<c, rest::binary>> = string, acc) do
    case c do
      ?N ->
        parse_route(rest, [:n | acc])

      ?E ->
        parse_route(rest, [:e | acc])

      ?S ->
        parse_route(rest, [:s | acc])

      ?W ->
        parse_route(rest, [:w | acc])

      ?( ->
        {branches, <<?), rest::binary>>} = parse_branches(rest)
        parse_route(rest, [branches | acc])

      _ ->
        {Enum.reverse(acc), string}
    end
  end

  defp parse_branches(string), do: parse_branches(string, [])

  defp parse_branches(string, acc) do
    {route, <<c, rest::binary>> = string} = parse_route(string)

    case c do
      ?| -> parse_branches(rest, [route | acc])
      _ -> {Enum.reverse([route | acc]), string}
    end
  end

  @doc """
  Formats the map as a string.

      iex> Day20.parse_routes("^WNE$") |>
      ...> Day20.build_map() |>
      ...> Day20.format_map()
      \"""
      #####
      #.|.#
      #-###
      #.|X#
      #####
      \"""
  """
  def format_map(map) do
    locations = Map.keys(map)
    {{min_x, _}, {max_x, _}} = Enum.min_max_by(locations, fn {x, _y} -> x end)
    {{_, min_y}, {_, max_y}} = Enum.min_max_by(locations, fn {_x, y} -> y end)

    for y <- min_y..max_y do
      for x <- min_x..max_x, into: "" do
        case map[{x, y}] do
          :wall -> "#"
          :room -> "."
          :door -> if map[{x - 1, y}] in [:room, :start], do: "|", else: "-"
          :start -> "X"
          :maybe_door -> "?"
          # Unreachable areas, occurs for fake inputs and incomplete maps.
          nil -> " "
        end
      end
    end
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  def dump_map(map) do
    File.write!("day20_output.txt", format_map(map))
    map
  end

  @doc """
  Builds the map from the routes.

      iex> routes = Day20.parse_routes("^ENWWW(NEEE|SSE(EE|N))$")
      iex> Day20.build_map(routes) |> Day20.format_map()
      \"""
      #########
      #.|.|.|.#
      #-#######
      #.|.|.|.#
      #-#####-#
      #.#.#X|.#
      #-#-#####
      #.|.|.|.#
      #########
      \"""

      iex> routes = Day20.parse_routes("^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$")
      iex> Day20.build_map(routes) |> Day20.format_map()
      \"""
      #############
      #.|.|.|.|.|.#
      #-#####-###-#
      #.#.|.#.#.#.#
      #-#-###-#-#-#
      #.#.#.|.#.|.#
      #-#-#-#####-#
      #.#.#.#X|.#.#
      #-#-#-###-#-#
      #.|.#.|.#.#.#
      ###-#-###-#-#
      #.|.#.|.|.#.#
      #############
      \"""

      iex> routes = Day20.parse_routes("^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$")
      iex> Day20.build_map(routes) |> Day20.format_map()
      \"""
      ###############
      #.|.|.|.#.|.|.#
      #-###-###-#-#-#
      #.|.#.|.|.#.#.#
      #-#########-#-#
      #.#.|.|.|.|.#.#
      #-#-#########-#
      #.#.#.|X#.|.#.#
      ###-#-###-#-#-#
      #.|.#.#.|.#.|.#
      #-###-#####-###
      #.|.#.|.|.#.#.#
      #-#-#####-#-#-#
      #.#.|.|.|.#.|.#
      ###############
      \"""
  """
  def build_map(routes) do
    {map, _locations} =
      %{}
      |> map_with_room({0, 0})
      |> Map.put({0, 0}, :start)
      |> build_map({0, 0}, routes)

    map
    |> fill_map()
    |> translate_map()
  end

  defp build_map(map, locations, []) do
    {map, locations}
  end

  defp build_map(map, locations, route) when is_list(locations) do
    Enum.reduce(locations, {map, []}, fn location, {map, locations} ->
      {map, location} = build_map(map, location, route)
      {map, [location | locations]}
    end)
  end

  defp build_map(map, {x, y}, [hd | tail]) do
    case hd do
      :n ->
        build_map_with_room(map, {x, y - 1}, {x, y - 2}, tail)

      :e ->
        build_map_with_room(map, {x + 1, y}, {x + 2, y}, tail)

      :s ->
        build_map_with_room(map, {x, y + 1}, {x, y + 2}, tail)

      :w ->
        build_map_with_room(map, {x - 1, y}, {x - 2, y}, tail)

      branches when is_list(branches) ->
        {map, locations} =
          Enum.reduce(branches, {map, []}, fn route, {map, locations} ->
            {map, location} = build_map(map, {x, y}, route)
            {map, [location | locations]}
          end)

        # The parsed routes form a tree. The number of possible routes grows
        # exponentially whenever we branch. Luckily many branches lead to the same
        # final poin so we can avoid double work. This is the key given the puzzle input.
        build_map(map, Enum.uniq(locations), tail)
    end
  end

  defp build_map_with_room(map, door_location, room_location, route) do
    map
    |> Map.put(door_location, :door)
    |> map_with_room(room_location)
    |> build_map(room_location, route)
  end

  defp map_with_room(map, {x, y}) do
    if map[{x, y}] == :room do
      map
    else
      map
      |> Map.put({x, y}, :room)
      |> Map.put({x - 1, y - 1}, :wall)
      |> Map.put({x + 1, y - 1}, :wall)
      |> Map.put({x - 1, y + 1}, :wall)
      |> Map.put({x + 1, y + 1}, :wall)
      |> Map.update({x, y - 1}, :maybe_door, & &1)
      |> Map.update({x, y + 1}, :maybe_door, & &1)
      |> Map.update({x - 1, y}, :maybe_door, & &1)
      |> Map.update({x + 1, y}, :maybe_door, & &1)
    end
  end

  # Fills the unknown spots with walls.
  defp fill_map(map) do
    map
    |> Enum.map(fn {location, value} ->
      if value == :maybe_door do
        {location, :wall}
      else
        {location, value}
      end
    end)
    |> Enum.into(%{})
  end

  # Translates the map so that the top left corner is at {1, 1}.
  defp translate_map(map) do
    locations = Map.keys(map)
    {min_x, _} = Enum.min_by(locations, fn {x, _y} -> x end)
    {_, min_y} = Enum.min_by(locations, fn {_x, y} -> y end)

    map
    |> Enum.map(fn {{x, y}, value} -> {{x - min_x + 1, y - min_y + 1}, value} end)
    |> Enum.into(%{})
  end

  @doc """
  Returns the distance to the furthest room.

      iex> Day20.parse_routes("^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$") |>
      ...> Day20.build_map() |>
      ...> Day20.furthest_room_distance()
      23

      iex> Day20.parse_routes("^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$") |>
      ...> Day20.build_map() |>
      ...> Day20.furthest_room_distance()
      31
  """
  def furthest_room_distance(map) do
    map
    |> min_distances()
    |> Map.values()
    |> Enum.max()
  end

  @doc """
  Calculates minimum distances from the start for all the rooms.

      iex> routes = Day20.parse_routes("^ENWWW(NEEE|SSE(EE|N))$")
      iex> map = Day20.build_map(routes)
      iex> Day20.format_map(map)
      \"""
      #########
      #.|.|.|.#
      #-#######
      #.|.|.|.#
      #-#####-#
      #.#.#X|.#
      #-#-#####
      #.|.|.|.#
      #########
      \"""
      iex> distances = Day20.min_distances(map)
      iex> distances[{6, 6}]
      0
      iex> distances[{2, 4}]
      5
  """
  def min_distances(map) do
    # Find the distances by doing breadth-first search from the start.
    {start, :start} = Enum.find(map, fn {_location, value} -> value == :start end)
    queue = :queue.new()
    min_distances(map, :queue.in({start, 0}, queue), %{start => 0})
  end

  defp min_distances(map, queue, distances) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        distances

      {{:value, {{x, y}, distance}}, queue} ->
        {next_queue, next_distances} =
          [{0, -1}, {0, +1}, {+1, 0}, {-1, 0}]
          |> Enum.filter(fn {dx, dy} ->
            map[{x + dx, y + dy}] == :door and !Map.has_key?(distances, {x + 2 * dx, y + 2 * dy})
          end)
          |> Enum.map(fn {dx, dy} -> {x + 2 * dx, y + 2 * dy} end)
          |> Enum.reduce({queue, distances}, fn location, {queue, distances} ->
            {
              :queue.in({location, distance + 1}, queue),
              Map.put(distances, location, distance + 1)
            }
          end)

        min_distances(map, next_queue, next_distances)
    end
  end

  def input() do
    "day20_input.txt"
    |> File.read!()
    |> String.trim()
    |> parse_routes()
    |> build_map()
    |> dump_map()
  end

  def part1() do
    input() |> furthest_room_distance()
  end

  def part2() do
    input()
    |> min_distances()
    |> Enum.count(fn {_location, distance} -> distance >= 1000 end)
  end
end
