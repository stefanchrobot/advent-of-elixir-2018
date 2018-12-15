defmodule Day03 do
  def input() do
    "day03_input.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  @claim_re ~r/#(\d+) @ (\d+),(\d+)\: (\d+)x(\d+)/

  def parse_claim(row) do
    [claim_id, left, top, width, height] =
      Regex.run(@claim_re, row, capture: :all_but_first)
      |> Enum.map(&String.to_integer/1)

    {claim_id, left, top, width, height}
  end

  def claims() do
    input()
    |> Enum.map(&parse_claim/1)
  end

  def to_claim_points({claim_id, left, top, width, height}) do
    for x <- left..(left + width - 1), y <- top..(top + height - 1) do
      {claim_id, {x, y}}
    end
  end

  def fabric_usage(claims) do
    claims
    |> Enum.flat_map(&to_claim_points/1)
    |> Enum.reduce(%{}, fn {claim_id, point}, acc ->
      Map.update(acc, point, [claim_id], &[claim_id | &1])
    end)
  end

  def part1 do
    claims()
    |> fabric_usage()
    |> Enum.count(fn {_point, claim_ids} -> length(claim_ids) > 1 end)
  end

  def part2 do
    claims = claims()

    all_claim_ids =
      claims
      |> Enum.map(fn {claim_id, _, _, _, _} -> claim_id end)
      |> Enum.into(MapSet.new())

    overlapping_claim_ids =
      fabric_usage(claims)
      |> Enum.reduce(MapSet.new(), fn {_point, claim_ids}, overlapping_claim_ids ->
        if length(claim_ids) > 1 do
          MapSet.union(overlapping_claim_ids, MapSet.new(claim_ids))
        else
          overlapping_claim_ids
        end
      end)

    MapSet.difference(all_claim_ids, overlapping_claim_ids)
    |> Enum.to_list()
    |> IO.inspect()
    |> hd()
  end
end
