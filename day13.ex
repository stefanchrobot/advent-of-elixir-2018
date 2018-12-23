defmodule Day13 do
  @doc ~S'''
  Parses the tracks and the carts.

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> /->-\
      ...> |   |  /----\
      ...> | /-+--+-\  |
      ...> | | |  | v  |
      ...> \-+-/  \-+--/
      ...>   \------/
      ...> """)
      iex> tracks[{0, 0}]
      :right_turn
      iex> tracks[{1, 0}]
      :vertical
      iex> tracks[{1, 0}]
      :vertical
      iex> tracks[{0, 1}]
      :horizontal
      iex> tracks[{0, 4}]
      :left_turn
      iex> tracks[{2, 4}]
      :intersection
      iex> carts
      [{{9, 3}, :down, :left}, {{2, 0}, :right, :left}]
  '''
  def parse_input(string) do
    string
    |> String.split("\n")
    |> Enum.with_index(0)
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.graphemes()
      |> Enum.with_index(0)
      |> Enum.map(fn {char, x} -> {x, y, char} end)
    end)
    |> Enum.reduce({%{}, []}, fn {x, y, char}, {tracks, carts} ->
      case char do
        "-" -> {Map.put(tracks, {x, y}, :vertical), carts}
        "|" -> {Map.put(tracks, {x, y}, :horizontal), carts}
        # This is both right and left turn, depending on the direction from which it is approached,
        # but named it :right_turn for the lack of a better name.
        "/" -> {Map.put(tracks, {x, y}, :right_turn), carts}
        "\\" -> {Map.put(tracks, {x, y}, :left_turn), carts}
        "+" -> {Map.put(tracks, {x, y}, :intersection), carts}
        # It might have been cleaner to use :north, :south, :east and :west for direction,
        # since :left and :right are also used for denoting turns. The puzzle uses that
        # wording so it's preserved here.
        ">" -> {Map.put(tracks, {x, y}, :vertical), [{{x, y}, :right, :left} | carts]}
        "<" -> {Map.put(tracks, {x, y}, :vertical), [{{x, y}, :left, :left} | carts]}
        "^" -> {Map.put(tracks, {x, y}, :horizontal), [{{x, y}, :up, :left} | carts]}
        "v" -> {Map.put(tracks, {x, y}, :horizontal), [{{x, y}, :down, :left} | carts]}
        _ -> {tracks, carts}
      end
    end)
  end

  def simple_loop() do
    ~S"""
    /->-\
    |   |
    |   |
    |   |
    \---/
    """
  end

  def single_cart() do
    ~S"""
    /->-\
    |   |  /----\
    | /-+--+-\  |
    | | |  | |  |
    \-+-/  \-+--/
      \------/
    """
  end

  def example() do
    ~S"""
    /->-\
    |   |  /----\
    | /-+--+-\  |
    | | |  | v  |
    \-+-/  \-+--/
      \------/
    """
  end

  def input() do
    "day13_input.txt"
    |> File.read!()
  end

  @doc ~S'''
  Converts the tracks and carts to a map.

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> /->-\
      ...> |   |  /----\
      ...> | /-+--+-\  |
      ...> | | |  | v  |
      ...> \-+-/  \-+--/
      ...>   \------/
      ...> """)
      iex> Day13.format_tracks_and_carts(tracks, carts)
      ~S"""
      /->-\
      |   |  /----\
      | /-+--+-\  |
      | | |  | v  |
      \-+-/  \-+--/
        \------/
      """
  '''
  def format_tracks_and_carts(tracks, carts, colors? \\ false) do
    map =
      carts
      |> Enum.reduce(tracks, fn {{x, y}, dir, _next_turn}, tracks ->
        Map.put(tracks, {x, y}, dir)
      end)
      |> Enum.map(fn {point, item} ->
        char =
          case item do
            :vertical -> "-"
            :horizontal -> "|"
            :right_turn -> "/"
            :left_turn -> "\\"
            :intersection -> "+"
            :right -> cart(">", colors?)
            :left -> cart("<", colors?)
            :up -> cart("^", colors?)
            :down -> cart("v", colors?)
          end

        {point, char}
      end)
      |> Enum.into(%{})

    {max_x, max_y} =
      Enum.reduce(map, {0, 0}, fn {{x, y}, _char}, {max_x, max_y} ->
        {max(max_x, x), max(max_y, y)}
      end)

    for y <- 0..max_y, into: "" do
      for(x <- 0..max_x, into: "", do: Map.get(map, {x, y}, " "))
      |> String.trim_trailing()
      |> Kernel.<>("\n")
    end
  end

  defp cart(string, colors?) do
    if colors? do
      IO.ANSI.blue() <> string <> IO.ANSI.white()
    else
      string
    end
  end

  @doc ~S'''
  Moves the cart along the tracks.

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> /->-\
      ...> |   |
      ...> | /-+-\
      ...> | | | |
      ...> \-+-/ |
      ...>   \---/
      ...> """)
      iex> cart = hd(carts)
      {{2, 0}, :right, :left}
      iex> cart = Day13.move_cart(tracks, cart)
      {{3, 0}, :right, :left}
      iex> cart = Day13.move_cart(tracks, cart)
      {{4, 0}, :down, :left}
      iex> cart = Day13.move_cart(tracks, cart)
      {{4, 1}, :down, :left}
      iex> cart = Day13.move_cart(tracks, cart)
      {{4, 2}, :right, :straight}
      iex> Day13.move_cart(tracks, cart)
      {{5, 2}, :right, :straight}
  '''
  def move_cart(tracks, {{x, y}, direction, next_turn}) do
    new_position = move_forward({x, y}, direction)

    case tracks[new_position] do
      :horizontal ->
        {new_position, direction, next_turn}

      :vertical ->
        {new_position, direction, next_turn}

      :right_turn ->
        {new_position, take_right_turn(direction), next_turn}

      :left_turn ->
        {new_position, take_left_turn(direction), next_turn}

      :intersection ->
        {new_direction, new_next_turn} =
          case next_turn do
            :left -> {go_left(direction), :straight}
            :straight -> {go_straight(direction), :right}
            :right -> {go_right(direction), :left}
          end

        {new_position, new_direction, new_next_turn}
    end
  end

  # Calculates the next position given the direction.
  defp move_forward({x, y}, direction) do
    case direction do
      :right -> {x + 1, y}
      :left -> {x - 1, y}
      :up -> {x, y - 1}
      :down -> {x, y + 1}
    end
  end

  # Takes the right turn given the direction.
  defp take_right_turn(direction) do
    case direction do
      :right -> :up
      :left -> :down
      :up -> :right
      :down -> :left
    end
  end

  # Takes the left turn given the direction.
  defp take_left_turn(direction) do
    case direction do
      :right -> :down
      :left -> :up
      :up -> :left
      :down -> :right
    end
  end

  # Goes left on the intersection.
  defp go_left(direction) do
    case direction do
      :up -> :left
      :left -> :down
      :down -> :right
      :right -> :up
    end
  end

  # Goes straight on the intersection.
  defp go_straight(direction), do: direction

  # Goes right on the intersection.
  defp go_right(direction) do
    case direction do
      :up -> :right
      :right -> :down
      :down -> :left
      :left -> :up
    end
  end

  @doc ~S'''
  Moves all the carts along the tracks.

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> /->-\
      ...> |   |  /----\
      ...> | /-+--+-\  |
      ...> | | |  | v  |
      ...> \-+-/  \-+--/
      ...>   \------/
      ...> """)
      iex> Day13.move_carts(tracks, carts)
      {:moved, [{{3, 0}, :right, :left}, {{9, 4}, :right, :straight}]}

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> /---\
      ...> |   |  /----\
      ...> | /-+--v-\  |
      ...> | | |  | |  |
      ...> \-+-/  ^-+--/
      ...>   \------/
      ...> """)
      iex> Day13.move_carts(tracks, carts)
      {:crash, {7, 3}}
  '''
  def move_carts(tracks, carts) do
    ordered_carts = Enum.sort_by(carts, fn {{x, y}, _direction, _next_turn} -> {y, x} end)

    cart_positions =
      carts
      |> Enum.map(fn {position, _direction, _next_turn} -> position end)
      |> Enum.into(MapSet.new())

    move_carts(tracks, cart_positions, ordered_carts, [])
  end

  defp move_carts(_tracks, _cart_positions, [], moved) do
    {:moved, Enum.reverse(moved)}
  end

  defp move_carts(tracks, cart_positions, [{position, _, _} = cart | to_move], moved) do
    {new_position, _, _} = moved_cart = move_cart(tracks, cart)

    if new_position in cart_positions do
      {:crash, new_position}
    else
      new_cart_positions =
        cart_positions
        |> MapSet.delete(position)
        |> MapSet.put(new_position)

      move_carts(tracks, new_cart_positions, to_move, [moved_cart | moved])
    end
  end

  @doc """
  Animates the movement of carts along the tracks.
  """
  def animate(input, iterations \\ 100) do
    {tracks, carts} = parse_input(input)

    Enum.reduce_while(1..iterations, carts, fn _x, carts ->
      IO.write([IO.ANSI.home(), IO.ANSI.clear()])
      format_tracks_and_carts(tracks, carts, true) |> IO.puts()
      Process.sleep(300)

      case move_carts(tracks, carts) do
        {:moved, carts} ->
          {:cont, carts}

        {:crash, location} ->
          IO.puts("crash at #{inspect(location)}")
          {:halt, location}
      end
    end)
  end

  def move_until_crash(tracks, carts) do
    case move_carts(tracks, carts) do
      {:moved, carts} -> move_until_crash(tracks, carts)
      {:crash, location} -> location
    end
  end

  def part1() do
    {tracks, carts} = input() |> parse_input()
    move_until_crash(tracks, carts)
  end

  @doc ~S'''
  Returns the remaining cart after all the other carts crash.

      iex> {tracks, carts} = Day13.parse_input(~S"""
      ...> />-<\
      ...> |   |
      ...> | /<+-\
      ...> | | | v
      ...> \>+</ |
      ...>   |   ^
      ...>   \<->/
      ...> """)
      iex> Day13.find_remaining_cart(tracks, carts)
      {{6, 4}, :up, :left}
  '''
  def find_remaining_cart(_tracks, [cart]) do
    cart
  end

  def find_remaining_cart(tracks, carts) do
    ordered_carts = Enum.sort_by(carts, fn {{x, y}, _direction, _next_turn} -> {y, x} end)

    cart_positions =
      carts
      |> Enum.map(fn {position, _direction, _next_turn} -> position end)
      |> Enum.into(MapSet.new())

    find_remaining_cart(tracks, cart_positions, ordered_carts, [])
  end

  defp find_remaining_cart(tracks, _cart_positions, [], moved) do
    find_remaining_cart(tracks, moved)
  end

  defp find_remaining_cart(tracks, cart_positions, [{position, _, _} = cart | to_move], moved) do
    {new_position, _, _} = moved_cart = move_cart(tracks, cart)

    if new_position in cart_positions do
      new_cart_positions =
        cart_positions
        |> MapSet.delete(position)
        |> MapSet.delete(new_position)

      new_to_move = Enum.reject(to_move, fn {pos, _, _} -> pos == new_position end)
      new_moved = Enum.reject(moved, fn {pos, _, _} -> pos == new_position end)

      find_remaining_cart(tracks, new_cart_positions, new_to_move, new_moved)
    else
      new_cart_positions =
        cart_positions
        |> MapSet.delete(position)
        |> MapSet.put(new_position)

      find_remaining_cart(tracks, new_cart_positions, to_move, [moved_cart | moved])
    end
  end

  def part2() do
    {tracks, carts} = input() |> parse_input()
    find_remaining_cart(tracks, carts)
  end
end
