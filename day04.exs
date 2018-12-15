defmodule Day04 do
  def input() do
    "day4_input.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.sort()
    |> Enum.map(&parse_entry/1)
  end

  def parse_entry(string) do
    [year, month, day, hour, minute] =
      string
      |> String.slice(1..16)
      |> String.split(["-", " ", ":"])
      |> Enum.map(&String.to_integer/1)

    event =
      case String.slice(string, 19..-1) do
        "wakes up" ->
          :wakes_up

        "falls asleep" ->
          :falls_asleep

        begins_shift ->
          ["Guard", guard_id, "begins", "shift"] = String.split(begins_shift, [" #", " "])
          {:begins_shift, String.to_integer(guard_id)}
      end

    {{year, month, day, hour, minute}, event}
  end

  def to_sleep_times(entries) do
    Enum.reduce(entries, {nil, nil, []}, fn {date_time, event},
                                            {guard_id, falls_asleep, sleep_times} ->
      case event do
        {:begins_shift, new_guard_id} -> {new_guard_id, nil, sleep_times}
        :falls_asleep -> {guard_id, date_time, sleep_times}
        :wakes_up -> {guard_id, nil, [{guard_id, falls_asleep, date_time} | sleep_times]}
      end
    end)
    |> elem(2)
    |> Enum.reverse()
  end

  def sleep_length(
        {_year1, _month1, _day1, _hour1, asleep_minute},
        {_year2, _month2, _day2, _hour2, awake_minute}
      ) do
    awake_minute - asleep_minute
  end

  def part1() do
    sleep_times =
      input()
      |> to_sleep_times()

    {sleepiest_guard_id, _total_sleep_time} =
      sleep_times
      |> Enum.map(fn {guard_id, asleep, awake} -> {guard_id, sleep_length(asleep, awake)} end)
      |> Enum.reduce(%{}, fn {guard_id, sleep_time}, acc ->
        Map.update(acc, guard_id, sleep_time, &(&1 + sleep_time))
      end)
      |> Enum.to_list()
      |> Enum.max_by(fn {_guard_id, sleep_time} -> sleep_time end)

    {sleepiest_minute, _sleep_count} =
      sleep_times
      |> Enum.filter(fn {guard_id, _asleep, _awake} -> guard_id == sleepiest_guard_id end)
      |> Enum.flat_map(fn {_guard_id, {_, _, _, _, asleep_minute}, {_, _, _, _, awake_minute}} ->
        Enum.to_list(asleep_minute..(awake_minute - 1))
      end)
      |> Enum.reduce(%{}, fn minute, acc -> Map.update(acc, minute, 1, &(&1 + 1)) end)
      |> Enum.to_list()
      |> Enum.max_by(fn {_minute, sleep_count} -> sleep_count end)

    sleepiest_guard_id * sleepiest_minute
  end

  def part2() do
    sleep_times =
      input()
      |> to_sleep_times()

    {{guard_id, minute}, _count} =
      sleep_times
      |> Enum.flat_map(fn {guard_id, {_, _, _, _, asleep_minute}, {_, _, _, _, awake_minute}} ->
        Enum.map(asleep_minute..(awake_minute - 1), fn minute -> {guard_id, minute} end)
      end)
      |> Enum.reduce(%{}, fn key, acc -> Map.update(acc, key, 1, &(&1 + 1)) end)
      |> Enum.to_list()
      |> Enum.max_by(fn {_key, sleep_count} -> sleep_count end)

    guard_id * minute
  end
end
