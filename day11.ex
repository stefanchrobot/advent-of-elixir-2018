defmodule Day11 do
  @doc """
  Calculates the power level of a cell in a grid.

      iex> Day11.power_level({122, 79}, 57)
      -5

      iex> Day11.power_level({217, 196}, 39)
      0

      iex> Day11.power_level({101 ,153}, 71)
      4
  """
  def power_level({x, y}, grid_serial_number) do
    rack_id = x + 10
    level = (rack_id * y + grid_serial_number) * rack_id

    digit = level |> div(100) |> rem(10)
    digit - 5
  end

  @grid_size 300

  @doc """
  Finds the top-left corner of the square with the biggest total power level.

      iex> Day11.best_square_3x3(18)
      {{33, 45}, 29}

      iex> Day11.best_square_3x3(42)
      {{21, 61}, 30}
  """
  def best_square_3x3(grid_serial_number) do
    total_power_levels =
      for x <- 1..(@grid_size - 2),
          y <- 1..(@grid_size - 2) do
        cells = for cx <- x..(x + 2), cy <- y..(y + 2), do: {cx, cy}

        total_power_level =
          cells
          |> Enum.map(&power_level(&1, grid_serial_number))
          |> Enum.sum()

        {{x, y}, total_power_level}
      end

    Enum.max_by(total_power_levels, fn {_cell, power_level} -> power_level end)
  end

  def part1() do
    {{x, y}, _power_level} = best_square_3x3(9995)
    "#{x},#{y}"
  end

  @doc """
  Finds the top-left corner of the square with the biggest total power level.

      iex> Day11.best_square(18, 16)
      {{90, 269, 16}, 113}

      iex> Day11.best_square(42, 12)
      {{232, 251, 12}, 119}
  """
  def best_square(grid_serial_number, max_square_size) do
    Enum.reduce(1..max_square_size, %{}, fn size, memo ->
      best_square(memo, size, grid_serial_number)
    end)
    |> Enum.max_by(fn {_square, power_level} -> power_level end)
  end

  defp best_square(memo, 1, grid_serial_number) do
    IO.puts(1)

    for x <- 1..@grid_size,
        y <- 1..@grid_size,
        into: memo,
        do: {{x, y, 1}, power_level({x, y}, grid_serial_number)}
  end

  defp best_square(memo, size, _grid_serial_number) when rem(size, 2) == 0 do
    IO.puts(size)

    for x <- 1..(@grid_size - size + 1),
        y <- 1..(@grid_size - size + 1),
        into: memo do
      half = div(size, 2)

      power_level =
        memo[{x, y, half}] + memo[{x + half, y, half}] + memo[{x, y + half, half}] +
          memo[{x + half, y + half, half}]

      {{x, y, size}, power_level}
    end
  end

  defp best_square(memo, size, _grid_serial_number) when rem(size, 2) == 1 do
    IO.puts(size)

    for x <- 1..(@grid_size - size + 1),
        y <- 1..(@grid_size - size + 1),
        into: memo do
      half = div(size, 2)

      filler =
        1..half
        |> Enum.map(fn z ->
          memo[{x + half + z, y + half, 1}] + memo[{x + half, y + half + z, 1}]
        end)
        |> Enum.sum()

      power_level =
        memo[{x, y, half + 1}] + memo[{x + half + 1, y, half}] + memo[{x, y + half + 1, half}] +
          memo[{x + half + 1, y + half + 1, half}] + filler

      {{x, y, size}, power_level}
    end
  end

  def part2() do
    best_square(9995, 300)
  end
end
