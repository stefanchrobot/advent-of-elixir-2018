defmodule Day09 do
  @doc """
  Returns the score of the winning elf in the game of marles.

    iex> Day09.winning_score(9, 25)
    32

    iex> Day09.winning_score(10, 1618)
    8317

    iex> Day09.winning_score(13, 7999)
    146373

    iex> Day09.winning_score(17, 1104)
    2764

    iex> Day09.winning_score(21, 6111)
    54718

    iex> Day09.winning_score(30, 5807)
    37305
  """
  def winning_score(players, turns) do
    board = %{0 => {0, 0}}
    scores = 1..players |> Enum.map(&{&1, 0}) |> Enum.into(%{})

    {_current_marble, _board, scores} =
      1..turns
      |> Enum.reduce({0, board, scores}, fn turn, {current_marble, board, scores} ->
        next_marble = turn
        next_player = player(turn, players)

        if rem(next_marble, 23) == 0 do
          removed_marble = counter_clockwise(board, current_marble, 7)
          new_next_marble = clockwise(board, removed_marble, 1)
          board = remove_marble(board, removed_marble)
          scores = Map.update(scores, next_player, nil, &(&1 + next_marble + removed_marble))
          # print_board(next_player, board, next_marble)
          {new_next_marble, board, scores}
        else
          after_marble = clockwise(board, current_marble, 1)
          board = insert_marble(board, next_marble, after_marble)
          # print_board(next_player, board, next_marble)
          {next_marble, board, scores}
        end
      end)

    {_player, score} = Enum.max_by(scores, fn {_player, score} -> score end)
    score
  end

  @doc """
  Returns the number of the player whose turn is now.

      iex> Day09.player(1, 5)
      1

      iex> Day09.player(6, 5)
      1

      iex> Day09.player(12, 5)
      2
  """
  def player(turn, players) do
    rem(turn - 1, players) + 1
  end

  @doc """
  Returns the marble n steps clockwise.

      iex> Day09.clockwise(%{0 => {1, 1}, 1 => {0, 0}}, 1, 1)
      0

      iex> Day09.clockwise(%{0 => {1, 1}, 1 => {0, 0}}, 1, 2)
      1

      iex> Day09.clockwise(%{0 => {3, 4}, 4 => {0, 2}, 2 => {4, 1}, 1 => {2, 3}, 3 => {1, 0}}, 4, 1)
      2

      iex> Day09.clockwise(%{0 => {3, 4}, 4 => {0, 2}, 2 => {4, 1}, 1 => {2, 3}, 3 => {1, 0}}, 4, 2)
      1
  """
  def clockwise(_board, from_marble, 0), do: from_marble

  def clockwise(board, from_marble, steps) do
    {_prev, next} = board[from_marble]
    clockwise(board, next, steps - 1)
  end

  @doc """
  Returns the marble n steps counter-clockwise.

      iex> Day09.counter_clockwise(%{0 => {1, 1}, 1 => {0, 0}}, 1, 1)
      0

      iex> Day09.counter_clockwise(%{0 => {1, 1}, 1 => {0, 0}}, 1, 2)
      1

      iex> Day09.counter_clockwise(%{0 => {3, 4}, 4 => {0, 2}, 2 => {4, 1}, 1 => {2, 3}, 3 => {1, 0}}, 4, 3)
      1

      iex> Day09.counter_clockwise(%{0 => {3, 4}, 4 => {0, 2}, 2 => {4, 1}, 1 => {2, 3}, 3 => {1, 0}}, 3, 4)
      0
  """
  def counter_clockwise(_board, from_marble, 0), do: from_marble

  def counter_clockwise(board, from_marble, steps) do
    {prev, _next} = board[from_marble]
    counter_clockwise(board, prev, steps - 1)
  end

  @doc """
  Inserts the marble into the board after the specified marble.

    iex> Day09.insert_marble(%{0 => {0, 0}}, 1, 0)
    %{0 => {1, 1}, 1 => {0, 0}}

    iex> Day09.insert_marble(%{0 => {3, 2}, 2 => {0, 1}, 1 => {2, 3}, 3 => {1, 0}}, 4, 0)
    %{0 => {3, 4}, 4 => {0, 2}, 2 => {4, 1}, 1 => {2, 3}, 3 => {1, 0}}
  """
  def insert_marble(board, marble, after_marble) do
    if map_size(board) == 1 do
      %{after_marble => {marble, marble}, marble => {after_marble, after_marble}}
    else
      before_marble = clockwise(board, after_marble, 1)
      {after_left, ^before_marble} = board[after_marble]
      {^after_marble, before_right} = board[before_marble]

      board
      |> Map.put(after_marble, {after_left, marble})
      |> Map.put(marble, {after_marble, before_marble})
      |> Map.put(before_marble, {marble, before_right})
    end
  end

  @doc """
  Removes the marble from the board.

    iex> Day09.insert_marble(%{0 => {0, 0}}, 1, 0)
    %{0 => {1, 1}, 1 => {0, 0}}

    iex> Day09.remove_marble(%{0 => {3, 2}, 2 => {0, 1}, 1 => {2, 3}, 3 => {1, 0}}, 2)
    %{0 => {3, 1}, 1 => {0, 3}, 3 => {1, 0}}
  """
  def remove_marble(board, marble) do
    {left, right} = board[marble]
    {left_left, ^marble} = board[left]
    {^marble, right_right} = board[right]

    board
    |> Map.put(left, {left_left, right})
    |> Map.delete(marble)
    |> Map.put(right, {left, right_right})
  end

  def print_board(player, board, current_marble) do
    marbles_count = map_size(board)

    marbles =
      clockwise_marbles(board, 0, [], marbles_count)
      |> Enum.map(fn marble ->
        marble_str = marble |> to_string() |> String.pad_leading(2)

        if marble == current_marble do
          "(#{marble_str})"
        else
          " #{marble_str} "
        end
      end)
      |> Enum.join()

    IO.puts("[#{player}]#{marbles}")
  end

  defp clockwise_marbles(_board, _current_marble, marbles, 0) do
    Enum.reverse(marbles)
  end

  defp clockwise_marbles(board, current_marble, marbles, count) do
    {_prev, next} = board[current_marble]
    clockwise_marbles(board, next, [current_marble | marbles], count - 1)
  end

  def part1() do
    winning_score(479, 71035)
  end

  def part2() do
    winning_score(479, 71035 * 100)
  end
end
