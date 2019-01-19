defmodule Group do
  defstruct [
    :army,
    :id,
    :unit_count,
    :hit_points,
    :weaknesses,
    :immunities,
    :attack_damage,
    :attack_type,
    :initiative
  ]

  @doc """
  Parses the input.

      iex> Group.parse_input(
      ...> \"""
      ...> Immune System:
      ...> 504 units each with 1697 hit points (weak to fire; immune to slashing) with an attack that does 28 fire damage at initiative 4
      ...> 7779 units each with 6919 hit points (weak to bludgeoning) with an attack that does 7 cold damage at initiative 2
      ...>
      ...> Infection:
      ...> 442 units each with 35928 hit points with an attack that does 149 bludgeoning damage at initiative 11
      ...> \""" |> String.trim())
      [
        %Group{
          army: :immune_system,
          id: 1,
          unit_count: 504,
          hit_points: 1697,
          weaknesses: ["fire"],
          immunities: ["slashing"],
          attack_damage: 28,
          attack_type: "fire",
          initiative: 4
        },
        %Group{
          army: :immune_system,
          id: 2,
          unit_count: 7779,
          hit_points: 6919,
          weaknesses: ["bludgeoning"],
          immunities: [],
          attack_damage: 7,
          attack_type: "cold",
          initiative: 2
        },
        %Group{
          army: :infection,
          id: 1,
          unit_count: 442,
          hit_points: 35928,
          weaknesses: [],
          immunities: [],
          attack_damage: 149,
          attack_type: "bludgeoning",
          initiative: 11
        }
      ]
  """
  def parse_input(string) do
    rest = parse_prefix(string, "Immune System:\n")
    {immune_system, rest} = parse_army(rest, :immune_system)
    rest = parse_prefix(rest, "\nInfection:\n")
    {infection, ""} = parse_army(rest, :infection)

    immune_system ++ infection
  end

  def parse_army(string, army) do
    parse_army(string, army, 1, [])
  end

  def parse_army(<<>>, _army, _id, groups) do
    {Enum.reverse(groups), <<>>}
  end

  def parse_army(<<"\n", _::binary>> = rest, _army, _id, groups) do
    {Enum.reverse(groups), rest}
  end

  def parse_army(string, army, id, groups) do
    {group, rest} = parse_group(string)
    group = %{group | army: army, id: id}

    case rest do
      <<"\n", _::binary>> ->
        rest = parse_prefix(rest, "\n")
        parse_army(rest, army, id + 1, [group | groups])

      _ ->
        parse_army(rest, army, id + 1, [group | groups])
    end
  end

  def parse_group(string) do
    {unit_count, rest} = parse_integer(string)
    rest = parse_prefix(rest, " units each with ")
    {hit_points, rest} = parse_integer(rest)
    rest = parse_prefix(rest, " hit points ")
    {{weaknesses, immunities}, rest} = parse_attributes(rest)
    rest = parse_prefix(rest, "with an attack that does ")
    {attack_damage, rest} = parse_integer(rest)
    rest = parse_prefix(rest, " ")
    {attack_type, rest} = parse_word(rest)
    rest = parse_prefix(rest, " damage at initiative ")
    {initiative, rest} = parse_integer(rest)

    group = %Group{
      unit_count: unit_count,
      hit_points: hit_points,
      weaknesses: weaknesses,
      immunities: immunities,
      attack_damage: attack_damage,
      attack_type: attack_type,
      initiative: initiative
    }

    {group, rest}
  end

  def parse_integer(string) do
    parse_integer(string, [])
  end

  def parse_integer(<<c, rest::binary>>, acc) when c >= ?0 and c <= ?9 do
    parse_integer(rest, [c | acc])
  end

  def parse_integer(string, acc) do
    {acc |> Enum.reverse() |> to_string() |> String.to_integer(), string}
  end

  def parse_word(string) do
    parse_word(string, [])
  end

  def parse_word(<<c, rest::binary>>, acc) when c in ?a..?z or c in ?A..?Z do
    parse_word(rest, [c | acc])
  end

  def parse_word(rest, acc) do
    {acc |> Enum.reverse() |> to_string(), rest}
  end

  def parse_prefix(string, <<>>) do
    string
  end

  def parse_prefix(<<c, string_rest::binary>>, <<c, prefix_rest::binary>>) do
    parse_prefix(string_rest, prefix_rest)
  end

  def parse_attributes(<<"(", rest::binary>>) do
    parse_attributes(rest, [], [])
  end

  def parse_attributes(string) do
    {{[], []}, string}
  end

  def parse_attributes(<<"immune to ", rest::binary>>, weaknesses, []) do
    {types, rest} = parse_types(rest, [])
    parse_attributes(rest, weaknesses, types)
  end

  def parse_attributes(<<"weak to ", rest::binary>>, [], immunities) do
    {types, rest} = parse_types(rest, [])
    parse_attributes(rest, types, immunities)
  end

  def parse_attributes(<<"; ", rest::binary>>, weaknesses, immunities) do
    parse_attributes(rest, weaknesses, immunities)
  end

  def parse_attributes(<<") ", rest::binary>>, weaknesses, immunities) do
    {{weaknesses, immunities}, rest}
  end

  def parse_types(string, types) do
    case parse_word(string) do
      {type, <<", ", rest::binary>>} -> parse_types(rest, [type | types])
      {type, <<"; ", _::binary>> = rest} -> {[type | types] |> Enum.reverse(), rest}
      {type, <<") ", _::binary>> = rest} -> {[type | types] |> Enum.reverse(), rest}
    end
  end
end

defmodule Day24 do
  def example() do
    """
    Immune System:
    17 units each with 5390 hit points (weak to radiation, bludgeoning) with an attack that does 4507 fire damage at initiative 2
    989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3

    Infection:
    801 units each with 4706 hit points (weak to radiation) with an attack that does 116 bludgeoning damage at initiative 1
    4485 units each with 2961 hit points (immune to radiation; weak to fire, cold) with an attack that does 12 slashing damage at initiative 4
    """
    |> String.trim()
    |> Group.parse_input()
  end

  @doc """
  Returns unique id of the group.

      iex> Day24.unique_id(%Group{army: :immune_system, id: 2})
      {:immune_system, 2}
  """
  def unique_id(group) do
    {group.army, group.id}
  end

  @doc """
  Returns the effective power of the group.

      iex> Day24.effective_power(%Group{unit_count: 5, attack_damage: 7})
      35

      iex> Day24.example() |> Enum.map(&Day24.effective_power/1)
      [76_619, 24_725, 92_916, 53_820]
  """
  def effective_power(group) do
    group.unit_count * group.attack_damage
  end

  @doc """
  Returns the amount of damage that the attacker deals to the defender.

      iex> Day24.damage(
      ...> %Group{unit_count: 5, attack_damage: 7, attack_type: "fire"},
      ...> %Group{immunities: [], weaknesses: []})
      35

      iex> Day24.damage(
      ...> %Group{unit_count: 5, attack_damage: 7, attack_type: "fire"},
      ...> %Group{immunities: ["fire"], weaknesses: []})
      0

      iex> Day24.damage(
      ...> %Group{unit_count: 5, attack_damage: 7, attack_type: "fire"},
      ...> %Group{immunities: [], weaknesses: ["fire"]})
      70
  """
  def damage(attacker, defender) do
    power_coeff =
      cond do
        attacker.attack_type in defender.immunities -> 0
        attacker.attack_type in defender.weaknesses -> 2
        true -> 1
      end

    effective_power(attacker) * power_coeff
  end

  @doc """
  Performs target selection for each group.

      iex> Day24.example() |> Day24.select_targets()
      %{
        {:immune_system, 1} => {:infection, 2},
        {:immune_system, 2} => {:infection, 1},
        {:infection, 1} => {:immune_system, 1},
        {:infection, 2} => {:immune_system, 2}
      }
  """
  def select_targets(groups) do
    groups
    |> Enum.sort_by(fn group -> {-effective_power(group), -group.initiative} end)
    |> select_targets(groups, MapSet.new(), %{})
  end

  defp select_targets([], _groups, _used_targets, target_selection) do
    target_selection
  end

  defp select_targets([attacker | rest], groups, used_targets, target_selection) do
    {defender, _damage} =
      groups
      |> Enum.filter(fn defender ->
        defender.army != attacker.army && unique_id(defender) not in used_targets
      end)
      |> Enum.map(fn defender -> {defender, damage(attacker, defender)} end)
      |> Enum.filter(fn {_defender, damage} -> damage > 0 end)
      |> Enum.min_by(
        fn {defender, damage} -> {-damage, -effective_power(defender), -defender.initiative} end,
        fn -> {nil, nil} end
      )

    defender_id = if defender, do: unique_id(defender), else: nil

    select_targets(
      rest,
      groups,
      # It's fine to put nil here, since we search by valid unique ids.
      MapSet.put(used_targets, defender_id),
      Map.put(target_selection, unique_id(attacker), defender_id)
    )
  end

  @doc """
  Performs the attack for all groups

      iex> groups = Day24.example()
      iex> target_selection = Day24.select_targets(groups)
      iex> next_groups = Day24.attack(groups, target_selection)
      iex> Enum.map(next_groups, fn group -> {Day24.unique_id(group), group.unit_count} end)
      [
        {{:immune_system, 2}, 905},
        {{:infection, 1}, 797},
        {{:infection, 2}, 4434}
      ]
  """
  def attack(groups, target_selection) do
    groups_by_id = for group <- groups, into: %{}, do: {unique_id(group), group}

    groups
    |> Enum.sort_by(fn group -> -group.initiative end)
    |> Enum.map(&unique_id/1)
    |> Enum.reduce(groups_by_id, fn attacker_id, groups_by_id ->
      attack(attacker_id, target_selection[attacker_id], groups_by_id)
    end)
    |> Enum.sort_by(fn {unique_id, _group} -> unique_id end)
    |> Enum.map(fn {_unique_id, group} -> group end)
  end

  defp attack(attacker_id, defender_id, groups_by_id) do
    attacker = groups_by_id[attacker_id]
    defender = groups_by_id[defender_id]

    if attacker && defender do
      damage = damage(attacker, defender)
      units_killed = div(damage, defender.hit_points)

      if units_killed > defender.unit_count do
        Map.delete(groups_by_id, defender_id)
      else
        Map.put(groups_by_id, defender_id, %{
          defender
          | unit_count: defender.unit_count - units_killed
        })
      end
    else
      # Attacker already killed or no target selected.
      groups_by_id
    end
  end

  @doc """
  Performs the target selection and attack. Returns the groups after the attack
  or :deadlock if the combat is inconclusive.
  """
  def fight(groups) do
    target_selection = select_targets(groups)

    if deadlock?(target_selection) do
      :deadlock
    else
      attack(groups, target_selection)
    end
  end

  defp deadlock?(target_selection) do
    target_selection |> Map.values() |> Enum.uniq() == [nil]
  end

  @doc """
  Conducts the fight between armies until one of the armies is defeated.
  """
  def combat(groups) do
    armies =
      groups
      |> Enum.map(fn group -> group.army end)
      |> Enum.uniq()
      |> length()

    if armies == 2 do
      case fight(groups) do
        :deadlock -> groups
        # Units not powerful enough to progress the combat.
        ^groups -> groups
        next_groups -> combat(next_groups)
      end
    else
      groups
    end
  end

  @doc """
  Returns the count of remaining units of the winning army.

      iex> Day24.example() |> Day24.combat() |> Day24.remaining_units()
      5216
  """
  def remaining_units(groups) do
    groups
    |> Enum.map(fn group -> group.unit_count end)
    |> Enum.sum()
  end

  def input() do
    "day24_input.txt"
    |> File.read!()
    |> Group.parse_input()
  end

  def part1() do
    input()
    |> combat()
    |> remaining_units()
  end

  @doc """
  Returns the winner of the combat.
  """
  def winner(groups) do
    armies =
      groups
      |> Enum.map(fn group -> group.army end)
      |> Enum.uniq()

    case armies do
      [winner] -> winner
      [_, _] -> :tie
    end
  end

  @doc """
  Boosts the immune system.
  """
  def boost_immune_system(groups, boost) do
    Enum.map(groups, fn group ->
      if group.army == :immune_system do
        %{group | attack_damage: group.attack_damage + boost}
      else
        group
      end
    end)
  end

  @doc """
  Boosts the immune system and performs the combat until the immune system wins.
  """
  def boost_and_combat(groups) do
    boost_and_combat(groups, 0)
  end

  def boost_and_combat(groups, boost) do
    result =
      groups
      |> boost_immune_system(boost)
      |> combat()

    if winner(result) == :immune_system do
      result
    else
      boost_and_combat(groups, boost + 1)
    end
  end

  def part2() do
    input()
    |> boost_and_combat()
    |> remaining_units()
  end
end
