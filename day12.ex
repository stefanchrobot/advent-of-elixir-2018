defmodule Day12 do
  def input() do
    "day12_input.txt"
    |> File.read!()
    |> parse_input()
  end

  @doc """
  Parses the input. Returns the initial state and patterns for growth.

      iex> Day12.parse_input(\"""
      ...> initial state: ##.###.......#
      ...> #.#.# => #
      ...> .##.. => .
      ...> ..### => #
      ...> \""")
      {"##.###.......#", MapSet.new(["#.#.#", "..###"])}
  """
  def parse_input(string) do
    [<<"initial state: ", initial_state::binary>> | patterns] =
      String.split(string, "\n", trim: true)

    grow_patterns =
      patterns
      |> Enum.filter(&String.ends_with?(&1, "#"))
      |> Enum.map(&String.slice(&1, 0, 5))

    {initial_state, MapSet.new(grow_patterns)}
  end

  @doc """
  Generates next generation of plants given the state and the patterns of growth.

      iex> grow_patterns = MapSet.new(["...##", "..#..", ".#...", ".#.#.", ".#.##",
      ...>   ".##..", ".####", "#.#.#", "#.###", "##.#.", "##.##", "###..", "###.#", "####."])
      iex> Day12.next_generation("#..#.#..##......###...###", 0, grow_patterns)
      {"#...#....#.....#..#..#..#", 0}

      iex> grow_patterns = MapSet.new(["...##", "..#..", ".#...", ".#.#.", ".#.##",
      ...>   ".##..", ".####", "#.#.#", "#.###", "##.#.", "##.##", "###..", "###.#", "####."])
      iex> Day12.next_generation("#.#..#...#.#...#..#..##..##", 0, grow_patterns)
      {"#...##...#.#..#..#...#...#", 1}
  """
  def next_generation(state, first_pot, grow_patterns) do
    next_generation("....." <> state <> ".....", first_pot - 3, grow_patterns, "")
  end

  defp next_generation(state, first_pot, grow_patterns, acc) do
    if String.length(state) >= 5 do
      pattern = String.slice(state, 0, 5)
      result = if pattern in grow_patterns, do: "#", else: "."
      next_generation(String.slice(state, 1..-1), first_pot, grow_patterns, acc <> result)
    else
      {String.trim(acc, "."), first_pot + leading_blanks(acc, 0)}
    end
  end

  def leading_blanks(<<?.::utf8, rest::binary>>, count), do: leading_blanks(rest, count + 1)
  def leading_blanks(_string, count), do: count

  @doc """
  Sums the indices of the pots with flowers.

      iex> Day12.sum_pots("#.#.#.#", 0)
      12
  """
  def sum_pots(state, first_pot) do
    state
    |> String.graphemes()
    |> Enum.with_index(first_pot)
    |> Enum.reduce(0, fn {pot, index}, sum ->
      if pot == "#" do
        sum + index
      else
        sum
      end
    end)
  end

  def part1() do
    {initial_state, grow_patterns} = input()

    {state, first_pot} =
      Enum.reduce(1..20, {initial_state, 0}, fn _x, {state, first_pot} ->
        next_generation(state, first_pot, grow_patterns)
      end)

    sum_pots(state, first_pot)
  end

  @doc """
  Generates new generations until the state converges. Note that the whole pattern
  might still be in motion.
  """
  def converge(state, first_pot, grow_patterns) do
    converge(state, first_pot, grow_patterns, 1)
  end

  defp converge(state, first_pot, grow_patterns, generation) do
    {new_state, new_first_pot} = next_generation(state, first_pot, grow_patterns)

    if new_state == state do
      {new_state, new_first_pot, generation}
    else
      converge(new_state, new_first_pot, grow_patterns, generation + 1)
    end
  end

  def run_simulation() do
    {initial_state, grow_patterns} = input()

    Enum.reduce(1..10_000, {initial_state, 0}, fn _x, {state, first_pot} ->
      IO.write("\r" <> state <> " #{first_pot}")
      Process.sleep(100)
      next_generation(state, first_pot, grow_patterns)
    end)
  end

  @doc """
  For converged state, calculates the shift (left, stable or right) between generations.
  """
  def calculate_shift(state, first_pot, grow_patterns) do
    {_state, new_first_pot} = next_generation(state, first_pot, grow_patterns)
    new_first_pot - first_pot
  end

  def part2() do
    total_generations = 50_000_000_000
    {initial_state, grow_patterns} = input()

    {converged_state, first_pot, converged_after_generations} =
      converge(initial_state, 0, grow_patterns)

    shift = calculate_shift(converged_state, first_pot, grow_patterns)
    # Since the state converged, the only thing that changes is the index of the first pot.
    generations_left = total_generations - converged_after_generations
    sum_pots(converged_state, first_pot + shift * generations_left)
  end
end
