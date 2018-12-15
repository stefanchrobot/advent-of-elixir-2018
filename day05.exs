defmodule Day05 do
  def input() do
    "day05_input.txt"
    |> File.read!()
  end

  def part1(input \\ nil) do
    reduce_polymer([], input || input(), 0, 0)
  end

  def reduce_polymer(left, <<>>, _skip1, _skip2) do
    length(left)
  end

  def reduce_polymer(left, <<skip1::utf8, tail::binary>>, skip1, skip2) do
    reduce_polymer(left, tail, skip1, skip2)
  end

  def reduce_polymer(left, <<skip2::utf8, tail::binary>>, skip1, skip2) do
    reduce_polymer(left, tail, skip1, skip2)
  end

  def reduce_polymer([], <<head::utf8, tail::binary>>, skip1, skip2) do
    reduce_polymer([head], tail, skip1, skip2)
  end

  def reduce_polymer([left | left_rest], <<right::utf8, right_rest::binary>>, skip1, skip2) do
    if reactive?(left, right) do
      reduce_polymer(left_rest, right_rest, skip1, skip2)
    else
      reduce_polymer([right, left | left_rest], right_rest, skip1, skip2)
    end
  end

  def reactive?(left, right) do
    # ?a - ?A == 32
    abs(left - right) == 32
  end

  def part2 do
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    |> String.to_charlist()
    |> Enum.map(&reduce_polymer([], input(), &1, &1 + 32))
    |> Enum.min()
    |> IO.inspect()
  end

  def part2_concurrent do
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    |> String.to_charlist()
    |> Task.async_stream(&reduce_polymer([], input(), &1, &1 + 32))
    |> Enum.min()
    |> IO.inspect()
  end
end
