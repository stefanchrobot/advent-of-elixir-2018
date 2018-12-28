defmodule Cave do
  defstruct bounding_box: {1, 1, 1, 1}, map: %{}, units: %{}

  @doc """
  Adds a wall at the specified position.
  """
  def add_wall(cave, position) do
    %{
      cave
      | map: Map.put(cave.map, position, :wall),
        bounding_box: update_bounding_box(cave.bounding_box, position)
    }
  end

  @doc """
  Adds open cavern at the specified position.
  """
  def add_open_cavern(cave, position) do
    %{
      cave
      | map: Map.put(cave.map, position, :open),
        bounding_box: update_bounding_box(cave.bounding_box, position)
    }
  end

  @doc """
  Adds a unit of the specified type at the specified position.
  """
  def add_unit(cave, position, type) do
    unit_id = map_size(cave.units) + 1

    %{
      cave
      | map: Map.put(cave.map, position, {unit_id, type}),
        units: Map.put(cave.units, unit_id, {position, type, 200, 3}),
        bounding_box: update_bounding_box(cave.bounding_box, position)
    }
  end

  defp update_bounding_box({1, 1, max_x, max_y}, {x, y}) do
    {1, 1, max(max_x, x), max(max_y, y)}
  end

  @doc """
  Moves the specified unit to it's next position.
  """
  def move_unit(cave, unit_id, next_position) do
    {position, type, hit_points, attack_power} = cave.units[unit_id]

    %{
      cave
      | map: cave.map |> Map.put(position, :open) |> Map.put(next_position, {unit_id, type}),
        units: Map.put(cave.units, unit_id, {next_position, type, hit_points, attack_power})
    }
  end

  @doc """
  Returns true if the unit is still in the cave.
  """
  def unit_alive?(cave, unit_id) do
    Map.has_key?(cave.units, unit_id)
  end

  @doc """
  Removes the unit from the cave.
  """
  def die(cave, unit_id) do
    {position, _type, _hit_points, _attack_power} = cave.units[unit_id]
    %{cave | map: Map.put(cave.map, position, :open), units: Map.delete(cave.units, unit_id)}
  end

  @doc """
  Sets the hit points of the specified unit.
  """
  def set_hit_points(cave, unit_id, hit_points) do
    {position, type, _hit_points, attack_power} = cave.units[unit_id]
    %{cave | units: Map.put(cave.units, unit_id, {position, type, hit_points, attack_power})}
  end

  @doc """
  Sets the attack power of the specified unit.
  """
  def set_attack_power(cave, unit_id, attack_power) do
    {position, type, hit_points, _attack_power} = cave.units[unit_id]
    %{cave | units: Map.put(cave.units, unit_id, {position, type, hit_points, attack_power})}
  end

  @doc """
  Parses the cave.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.G.E.#
      ...> #E.G.E#
      ...> #.G.E.#
      ...> #######
      ...> \""")
      iex> cave.bounding_box
      {1, 1, 7, 5}
      iex> cave.map[{2, 1}]
      :wall
      iex> cave.map[{2, 2}]
      :open
      iex> cave.map[{3, 2}]
      {1, :goblin}
      iex> cave.map[{-2, -3}]
      nil
      iex> cave.units[2]
      {{5, 2}, :elf, 200, 3}
  """
  def parse(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.with_index(1)
    |> Enum.reduce(%Cave{}, fn {line, y}, cave ->
      line
      |> String.graphemes()
      |> Enum.with_index(1)
      |> Enum.reduce(cave, fn {char, x}, cave ->
        case char do
          "#" -> Cave.add_wall(cave, {x, y})
          "." -> Cave.add_open_cavern(cave, {x, y})
          "E" -> Cave.add_unit(cave, {x, y}, :elf)
          "G" -> Cave.add_unit(cave, {x, y}, :goblin)
        end
      end)
    end)
  end

  @doc """
  Converst the cave into a string.

      iex> \"""
      ...> #######
      ...> #.G.E.#
      ...> #E.G.E#
      ...> #.G.E.#
      ...> #######
      ...> \""" |> Cave.parse() |> Cave.format()
      \"""
      #######
      #.G.E.#
      #E.G.E#
      #.G.E.#
      #######
      \"""

      iex> \"""
      ...> #######
      ...> #.G...#
      ...> #...EG#
      ...> #.#.#G#
      ...> #..G#E#
      ...> #.....#
      ...> #######
      ...> \""" |> Cave.parse() |> Cave.format(with_hp: true)
      \"""
      #######
      #.G...#   G(200)
      #...EG#   E(200), G(200)
      #.#.#G#   G(200)
      #..G#E#   G(200), E(200)
      #.....#
      #######
      \"""
  """
  def format(cave, opts \\ [with_hp: false, with_colors: false]) do
    {min_x, min_y, max_x, max_y} = cave.bounding_box

    for y <- min_y..max_y do
      row =
        for x <- min_x..max_x, into: "" do
          case cave.map[{x, y}] do
            :wall ->
              "#"

            :open ->
              "."

            {unit_id, type} ->
              {_pos, _type, hit_points, _attack_power} = cave.units[unit_id]
              format_unit(type, hit_points, opts[:with_colors])

            nil ->
              " "
          end
        end

      hit_points =
        for x <- min_x..max_x, cave.map[{x, y}] not in [:wall, :open] do
          {id, type} = cave.map[{x, y}]
          {_pos, _type, hit_points, _attack_power} = cave.units[id]
          letter = if type == :elf, do: "E", else: "G"
          "#{letter}(#{hit_points})"
        end

      if opts[:with_hp] and hit_points != [] do
        row <> "   " <> Enum.join(hit_points, ", ")
      else
        row
      end
    end
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp format_unit(type, hit_points, with_colors?) do
    if type == :elf do
      if with_colors?, do: colored_text("E", 0, 127 + div(hit_points * 128, 200), 0), else: "E"
    else
      if with_colors?, do: colored_text("G", 127 + div(hit_points * 128, 200), 0, 0), else: "G"
    end
  end

  defp colored_text(text, r, g, b) do
    "\x1b[38;2;#{r};#{g};#{b}m#{text}\x1b[0m"
  end
end

defmodule Day15 do
  def input() do
    "day15_input.txt"
    |> File.read!()
    |> Cave.parse()
  end

  @doc """
  Returns the reading order (by row, then by column) for the specified position.

      iex> Enum.sort_by([{1, 2}, {1, 3}, {5, 1}], &Day15.reading_order/1)
      [{5, 1}, {1, 2}, {1, 3}]
  """
  def reading_order({x, y}) do
    {y, x}
  end

  @doc """
  Returns the adjecent positions in the reading order.

      iex> Day15.adjecent_positions({3, 3})
      [{3, 2}, {2, 3}, {4, 3}, {3, 4}]
  """
  def adjecent_positions({x, y}) do
    [{x, y - 1}, {x - 1, y}, {x + 1, y}, {x, y + 1}]
  end

  @doc """
  Returns true if the position contains enemy unit.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E..G.#
      ...> #...#.#
      ...> #.G.#G#
      ...> #######
      ...> \""")
      iex> Day15.enemy_at?(cave, {5, 2}, :elf)
      true
      iex> Day15.enemy_at?(cave, {5, 2}, :goblin)
      false
      iex> Day15.enemy_at?(cave, {15, 2}, :elf)
      false
  """
  def enemy_at?(cave, position, unit_type) do
    case cave.map[position] do
      {_unit_id, type} -> type != unit_type
      _ -> false
    end
  end

  @doc """
  Returns the path to the closest attack position or :no_path if no such path is available.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E..G.#
      ...> #...#.#
      ...> #.G.#G#
      ...> #######
      ...> \""")
      iex> Day15.closest_attack_position_path(cave, 1)
      [{2, 2}, {3, 2}, {4, 2}]

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.E...#
      ...> #.....#
      ...> #...G.#
      ...> #######
      ...> \""")
      iex> Day15.closest_attack_position_path(cave, 1)
      [{3, 2}, {4, 2}, {5, 2}, {5, 3}]

      iex> cave = Cave.parse(\"""
      ...> #########
      ...> #.G...G.#
      ...> #...G...#
      ...> #...E..G#
      ...> #.G.....#
      ...> #.......#
      ...> #G..G..G#
      ...> #.......#
      ...> #########
      ...> \""")
      iex> Day15.closest_attack_position_path(cave, 1)
      [{3, 2}, {4, 2}, {4, 3}, {4, 4}]
      iex> Day15.closest_attack_position_path(cave, 2)
      [{7, 2}, {6, 2}, {6, 3}, {6, 4}]
      iex> Day15.closest_attack_position_path(cave, 3)
      [{5, 3}]
      iex> Day15.closest_attack_position_path(cave, 4)
      [{5, 4}]
      iex> Day15.closest_attack_position_path(cave, 5)
      [{8, 4}, {7, 4}, {6, 4}]
      iex> Day15.closest_attack_position_path(cave, 6)
      [{3, 5}, {3, 4}, {4, 4}]
      iex> Day15.closest_attack_position_path(cave, 7)
      [{2, 7}, {2, 6}, {2, 5}, {2, 4}, {3, 4}, {4, 4}]
      iex> Day15.closest_attack_position_path(cave, 8)
      [{5, 7}, {5, 6}, {5, 5}]
      iex> Day15.closest_attack_position_path(cave, 9)
      [{8, 7}, {8, 6}, {8, 5}, {7, 5}, {7, 4}, {6, 4}]

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #G.#..#
      ...> #.#...#
      ...> ##..E.#
      ...> #######
      ...> \""")
      iex> Day15.closest_attack_position_path(cave, 1)
      :no_path
      iex> Day15.closest_attack_position_path(cave, 2)
      :no_path
  """
  def closest_attack_position_path(cave, unit_id) do
    {unit_position, unit_type, _hit_points, _attack_power} = cave.units[unit_id]
    queue = :queue.new()
    queue = :queue.in(unit_position, queue)
    best_path(cave, queue, %{unit_position => 0}, unit_position, unit_type)
  end

  defp best_path(cave, queue, distances, unit_position, unit_type) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        :no_path

      {{:value, position}, queue} ->
        # rely on reading order to move towards the right target
        adjecent = adjecent_positions(position)

        if Enum.any?(adjecent, fn pos -> enemy_at?(cave, pos, unit_type) end) do
          construct_best_path(unit_position, position, distances, [position])
        else
          distance_from_origin = distances[position]

          {next_queue, next_distances} =
            adjecent
            |> Enum.filter(fn pos -> cave.map[pos] == :open and distances[pos] == nil end)
            |> Enum.reduce({queue, distances}, fn pos, {queue, distances} ->
              {
                :queue.in(pos, queue),
                Map.put(distances, pos, distance_from_origin + 1)
              }
            end)

          best_path(cave, next_queue, next_distances, unit_position, unit_type)
        end
    end
  end

  # Builds the shortest path using the calculated distances by going backwards
  # from destination to origin.
  defp construct_best_path(origin, position, distances, path) do
    if position == origin do
      path
    else
      current_distance = distances[position]

      previous =
        position
        # rely on reading order to move along the proper path
        |> adjecent_positions()
        |> Enum.find(fn pos -> distances[pos] == current_distance - 1 end)

      construct_best_path(origin, previous, distances, [previous | path])
    end
  end

  @doc """
  Performs the move for the specified unit.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E..G.#
      ...> #...#.#
      ...> #.G.#G#
      ...> #######
      ...> \""")
      iex> Day15.perform_move(cave, 1) |> Cave.format()
      \"""
      #######
      #.E.G.#
      #...#.#
      #.G.#G#
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #G.#..#
      ...> #.#...#
      ...> ##..E.#
      ...> #######
      ...> \""")
      iex> Day15.perform_move(cave, 1) == cave
      true
  """
  def perform_move(cave, unit_id) do
    case closest_attack_position_path(cave, unit_id) do
      :no_path -> cave
      [_position] -> cave
      [_position, next_position | _rest] -> Cave.move_unit(cave, unit_id, next_position)
    end
  end

  @doc """
  Returns the attack target for the specified unit or nil if no targets available.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.G...#
      ...> #.EG.E#
      ...> #.G...#
      ...> #######
      ...> \""") |> Cave.set_hit_points(1, 100) |> Cave.set_hit_points(3, 50) |> Cave.set_hit_points(5, 50)
      iex> Day15.pick_attack_target(cave, 2)
      3
      iex> Day15.pick_attack_target(cave, 4)
      nil
  """
  def pick_attack_target(cave, unit_id) do
    {unit_position, unit_type, _hit_points, _attack_power} = cave.units[unit_id]

    unit_position
    # relay on reading order to pick the right target
    |> adjecent_positions()
    |> Enum.filter(fn pos -> enemy_at?(cave, pos, unit_type) end)
    |> Enum.map(fn pos ->
      {id, _type} = cave.map[pos]
      id
    end)
    |> Enum.min_by(
      fn id ->
        {_pos, _type, hit_points, _attack_power} = cave.units[id]
        hit_points
      end,
      fn -> nil end
    )
  end

  @doc """
  Performs the attack for the specified unit.

      iex> cave = Cave.parse(\"""
      ...> #####
      ...> #EG.#
      ...> #####
      ...> \""") |> Cave.set_hit_points(2, 100)
      iex> cave = Day15.perform_attack(cave, 1)
      iex> {_pos, _type, hit_points, _attack_power} = cave.units[2]
      iex> hit_points
      97

      iex> cave = Cave.parse(\"""
      ...> #####
      ...> #EG.#
      ...> #####
      ...> \""") |> Cave.set_hit_points(2, 1)
      iex> cave = Day15.perform_attack(cave, 1)
      iex> cave.map[{3, 2}]
      :open

      iex> cave = Cave.parse(\"""
      ...> #####
      ...> #E.G#
      ...> #####
      ...> \""")
      iex> Day15.perform_attack(cave, 1) == cave
      true
  """
  def perform_attack(cave, unit_id) do
    case pick_attack_target(cave, unit_id) do
      nil ->
        cave

      target_id ->
        {_pos, _type, _hit_points, attack_power} = cave.units[unit_id]
        {_pos, _type, hit_points, _attack_power} = cave.units[target_id]

        if hit_points <= attack_power do
          Cave.die(cave, target_id)
        else
          Cave.set_hit_points(cave, target_id, hit_points - attack_power)
        end
    end
  end

  @doc """
  Performs the next turn of the specified unit.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E..G.#
      ...> #...#.#
      ...> #.G.#G#
      ...> #######
      ...> \""")
      iex> Day15.next_unit_turn(cave, 1) |> Cave.format()
      \"""
      #######
      #.E.G.#
      #...#.#
      #.G.#G#
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E....#
      ...> #.....#
      ...> #.....#
      ...> #######
      ...> \""")
      iex> Day15.next_unit_turn(cave, 1)
      :combat_end
  """
  def next_unit_turn(cave, unit_id) do
    {_position, unit_type, _hit_points, _attack_power} = cave.units[unit_id]

    if !Enum.any?(cave.units, fn {_id, {_position, type, _hit_points, _attack_power}} ->
         type != unit_type
       end) do
      :combat_end
    else
      cave
      |> perform_move(unit_id)
      |> perform_attack(unit_id)
    end
  end

  @doc """
  Returns the order for the next round.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.G.E.#
      ...> #E.G.E#
      ...> #.G.E.#
      ...> #######
      ...> \""")
      iex> Day15.round_order(cave)
      [1, 2, 3, 4, 5, 6, 7]
  """
  def round_order(cave) do
    cave.units
    |> Enum.sort_by(fn {_id, {position, _type, _hit_points, _attack_power}} ->
      reading_order(position)
    end)
    |> Enum.map(fn {id, _unit} -> id end)
  end

  @doc """
  Performs the next turn for each unit. Returns tuple with the round status and the cave.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.G...#
      ...> #...EG#
      ...> #.#.#G#
      ...> #..G#E#
      ...> #.....#
      ...> #######
      ...> \""")
      iex> {:complete, cave} = Day15.next_round(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #..G..#   G(200)
      #...EG#   E(197), G(197)
      #.#G#G#   G(200), G(197)
      #...#E#   E(197)
      #.....#
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #G....#
      ...> #.G...#
      ...> #.#.#G#
      ...> #...#.#
      ...> #....G#
      ...> #######
      ...> \""")
      iex> Day15.next_round(cave) |> elem(0)
      :incomplete
  """
  def next_round(cave) do
    next_round(cave, round_order(cave))
  end

  defp next_round(cave, []) do
    {:complete, cave}
  end

  defp next_round(cave, [unit_id | rest]) do
    if Cave.unit_alive?(cave, unit_id) do
      case next_unit_turn(cave, unit_id) do
        :combat_end -> {:incomplete, cave}
        cave -> next_round(cave, rest)
      end
    else
      next_round(cave, rest)
    end
  end

  @doc """
  Continues rounds until the combat ends. Returns the cave and the number of completed rounds.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.G...#
      ...> #...EG#
      ...> #.#.#G#
      ...> #..G#E#
      ...> #.....#
      ...> #######
      ...> \""")
      iex> {cave, completed_rounds} = Day15.combat(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #G....#   G(200)
      #.G...#   G(131)
      #.#.#G#   G(59)
      #...#.#
      #....G#   G(200)
      #######
      \"""
      iex> completed_rounds
      47
  """
  def combat(cave) do
    combat(cave, 0)
  end

  defp combat(cave, completed_rounds) do
    case next_round(cave) do
      {:complete, cave} -> combat(cave, completed_rounds + 1)
      {:incomplete, cave} -> {cave, completed_rounds}
    end
  end

  @doc """
  Conducts the combats and calculates the stats. Returns the cave, completed rounds
  and the total remaining hit points.

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #G..#E#
      ...> #E#E.E#
      ...> #G.##.#
      ...> #...#E#
      ...> #...E.#
      ...> #######
      ...> \""")
      iex> {cave, 37, 982} = Day15.combat_with_stats(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #...#E#   E(200)
      #E#...#   E(197)
      #.E##.#   E(185)
      #E..#E#   E(200), E(200)
      #.....#
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E..EG#
      ...> #.#G.E#
      ...> #E.##E#
      ...> #G..#.#
      ...> #..E#.#
      ...> #######
      ...> \""")
      iex> {cave, 46, 859} = Day15.combat_with_stats(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #.E.E.#   E(164), E(197)
      #.#E..#   E(200)
      #E.##.#   E(98)
      #.E.#.#   E(200)
      #...#.#
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #E.G#.#
      ...> #.#G..#
      ...> #G.#.G#
      ...> #G..#.#
      ...> #...E.#
      ...> #######
      ...> \""")
      iex> {cave, 35, 793} = Day15.combat_with_stats(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #G.G#.#   G(200), G(98)
      #.#G..#   G(200)
      #..#..#
      #...#G#   G(95)
      #...G.#   G(200)
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #######
      ...> #.E...#
      ...> #.#..G#
      ...> #.###.#
      ...> #E#G#G#
      ...> #...#G#
      ...> #######
      ...> \""")
      iex> {cave, 54, 536} = Day15.combat_with_stats(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #######
      #.....#
      #.#G..#   G(200)
      #.###.#
      #.#.#.#
      #G.G#G#   G(98), G(38), G(200)
      #######
      \"""

      iex> cave = Cave.parse(\"""
      ...> #########
      ...> #G......#
      ...> #.E.#...#
      ...> #..##..G#
      ...> #...##..#
      ...> #...#...#
      ...> #.G...G.#
      ...> #.....G.#
      ...> #########
      ...> \""")
      iex> {cave, 20, 937} = Day15.combat_with_stats(cave)
      iex> Cave.format(cave, with_hp: true)
      \"""
      #########
      #.G.....#   G(137)
      #G.G#...#   G(200), G(200)
      #.G##...#   G(200)
      #...##..#
      #.G.#...#   G(200)
      #.......#
      #.......#
      #########
      \"""
  """
  def combat_with_stats(cave) do
    {cave, completed_rounds} = combat(cave)

    remaining_hit_points =
      cave.units
      |> Enum.map(fn {_id, {_pos, _type, hit_points, _attack_power}} -> hit_points end)
      |> Enum.sum()

    {cave, completed_rounds, remaining_hit_points}
  end

  @doc """
  Calculates the outcome of the combat.
  """
  def outcome({_cave, completed_rounds, remaining_hit_points}) do
    completed_rounds * remaining_hit_points
  end

  def part1() do
    input()
    |> combat_with_stats()
    |> outcome()
  end

  @doc """
  Returns the number of elves in the cave.

      iex> Cave.parse(\"""
      ...> #######
      ...> #.G...#
      ...> #...EG#
      ...> #.#.#G#
      ...> #..G#E#
      ...> #.....#
      ...> #######
      ...> \""") |> Day15.elves_count()
      2
  """
  def elves_count(cave) do
    Enum.count(cave.units, fn {_id, {_pos, type, _hit_points, _attack_power}} -> type == :elf end)
  end

  @doc """
  Determines if the elves won without a loss of a unit.
  """
  def elves_won_without_loss?(cave, initial_elves_count) do
    elves_count(cave) == initial_elves_count
  end

  @doc """
  Sets the attack power of all the elves to a specified value.
  """
  def set_elves_attack_power(cave, attack_power) do
    Enum.reduce(cave.units, cave, fn {id, {_pos, type, _hit_points, _attack_power}}, cave ->
      case type do
        :elf -> Cave.set_attack_power(cave, id, attack_power)
        :goblin -> cave
      end
    end)
  end

  @doc """
  Returns the combat with stats for the minimal attack power such that the elves win without a loss.
  """
  def minimum_elves_attack_power(cave) do
    minimum_elves_attack_power(cave, elves_count(cave), 4)
  end

  defp minimum_elves_attack_power(cave, initial_elves_count, attack_power) do
    {result_cave, _completed_rounds, _remaining_hit_points} =
      with_stats =
      cave
      |> set_elves_attack_power(attack_power)
      |> combat_with_stats()

    if elves_won_without_loss?(result_cave, initial_elves_count) do
      {attack_power, with_stats}
    else
      minimum_elves_attack_power(cave, initial_elves_count, attack_power + 1)
    end
  end

  def part2() do
    cave = input()
    {attack_power, combat_with_stats} = minimum_elves_attack_power(cave)
    {attack_power, outcome(combat_with_stats)}
  end

  def inspect_cave(cave) do
    IO.write([IO.ANSI.home(), IO.ANSI.clear()])
    cave |> Cave.format(with_hp: false, with_colors: true) |> IO.puts()
    Process.sleep(300)
    cave
  end

  def animate() do
    input = input() |> set_elves_attack_power(16)

    Stream.repeatedly(fn -> 0 end)
    |> Enum.reduce_while(input, fn _x, cave ->
      case next_round(cave) do
        {:complete, cave} -> {:cont, cave |> inspect_cave()}
        {:incomplete, cave} -> {:halt, cave |> inspect_cave()}
      end
    end)

    nil
  end
end
