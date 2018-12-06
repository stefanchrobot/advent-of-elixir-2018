defmodule Day2 do
  def input do
    "day2_input.txt"
    |> File.read!()
    |> String.split()
  end

  def part1 do
    {twos, threes} =
      input()
      |> Enum.map(fn box_id -> counts(box_id) end)
      |> Enum.reduce({0, 0}, fn {twos, threes}, {total_twos, total_threes} ->
        {total_twos + to_binary(twos), total_threes + to_binary(threes)}
      end)

    twos * threes
  end

  defp counts(box_id) do
    counts =
      box_id
      |> String.codepoints()
      |> Enum.reduce(%{}, fn codepoint, map ->
        Map.update(map, codepoint, 1, fn value -> value + 1 end)
      end)
      |> Map.values()

    {2 in counts, 3 in counts}
  end

  defp to_binary(flag) do
    if flag do
      1
    else
      0
    end
  end

  def len do
    26
  end

  def part2 do
    input()
    |> Enum.flat_map(fn id ->
      Enum.map(0..len(), fn x ->
        String.slice(id, 0, x) <> "_" <> String.slice(id, x + 1, len())
      end)
    end)
    |> Enum.reduce_while(MapSet.new(), fn x, set ->
      if x in set do
        {:halt, x}
      else
        {:cont, MapSet.put(set, x)}
      end
    end)
    |> String.replace("_", "")
  end
end
