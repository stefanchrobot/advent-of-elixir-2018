defmodule Day01 do
  def input do
    content = File.read!("day01_input.txt")
    Enum.map(String.split(content), fn x -> String.to_integer(x) end)
  end

  def part1 do
    Enum.sum(input())
  end

  def part2 do
    Enum.reduce_while(Stream.cycle(input()), {0, MapSet.new()}, fn x, acc ->
      current_freq = elem(acc, 0)
      seen_freqs = elem(acc, 1)
      next_freq = current_freq + x

      if next_freq in seen_freqs do
        {:halt, next_freq}
      else
        {:cont, {next_freq, MapSet.put(seen_freqs, next_freq)}}
      end
    end)
  end

  def part2_alt do
    inp = input()
    find_duplicate(inp, inp, 0, MapSet.new())
  end

  defp find_duplicate(input, original_input, current_freq, seen_freqs) do
    if input == [] do
      find_duplicate(original_input, original_input, current_freq, seen_freqs)
    else
      next_freq = current_freq + hd(input)

      if next_freq in seen_freqs do
        next_freq
      else
        find_duplicate(tl(input), original_input, next_freq, MapSet.put(seen_freqs, next_freq))
      end
    end
  end
end
