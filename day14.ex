defmodule Day14 do
  def input() do
    323_081
  end

  @doc """
  Combines two recipies to create a list of one or two recipes.
  Accepts recipes from 0 to 9.

      iex> Day14.combine_recipes(2, 3)
      [5]

      iex> Day14.combine_recipes(9, 7)
      [1, 6]
  """
  def combine_recipes(left, right) do
    sum = left + right

    if sum < 10 do
      [sum]
    else
      [1, sum - 10]
    end
  end

  @doc """
  Creates recipes by combining the previous ones.

      iex> Day14.create_recipes(2)
      [3, 7]

      iex> Day14.create_recipes(15)
      [3, 7, 1, 0, 1, 0, 1, 2, 4, 5, 1, 5, 8, 9, 1]
  """
  def create_recipes(count) do
    create_recipes(%{0 => 3, 1 => 7}, count - 2, 0, 1)
    |> Enum.take(count)
  end

  defp create_recipes(recipes, count, _elf_one, _elf_two) when count <= 0 do
    recipes
    |> Enum.sort_by(fn {index, _recipe} -> index end)
    |> Enum.map(fn {_index, recipe} -> recipe end)
  end

  defp create_recipes(recipes, count, elf_one, elf_two) do
    pre_count = map_size(recipes)

    {new_recipes, created} =
      case combine_recipes(recipes[elf_one], recipes[elf_two]) do
        [one] ->
          new_recipes = recipes |> Map.put(pre_count, one)
          {new_recipes, 1}

        [one, two] ->
          new_recipes = recipes |> Map.put(pre_count, one) |> Map.put(pre_count + 1, two)
          {new_recipes, 2}
      end

    post_count = pre_count + created
    new_elf_one = rem(elf_one + 1 + recipes[elf_one], post_count)
    new_elf_two = rem(elf_two + 1 + recipes[elf_two], post_count)
    create_recipes(new_recipes, count - created, new_elf_one, new_elf_two)
  end

  @doc """
  Returns the ten scores following [count] recipes.

      iex> Day14.ten_scores_after(9)
      "5158916779"

      iex> Day14.ten_scores_after(5)
      "0124515891"

      iex> Day14.ten_scores_after(18)
      "9251071085"
  """
  def ten_scores_after(count) do
    create_recipes(count + 10) |> Enum.drop(count) |> Enum.join()
  end

  def part1() do
    ten_scores_after(input())
  end

  @doc """
  Creates recipes until a score chain.

      iex> Day14.create_recipes_until("51589")
      9

      iex> Day14.create_recipes_until("01245")
      5

      iex> Day14.create_recipes_until("92510")
      18
  """
  def create_recipes_until(score_chain) do
    check_chains(%{0 => 3, 1 => 7, 2 => 1, 3 => 0, 4 => 1, 5 => 0}, 4, 3, "371010", score_chain)
  end

  defp check_chains(recipes, elf_one, elf_two, current_chain, score_chain) do
    cond do
      String.starts_with?(current_chain, score_chain) ->
        map_size(recipes) - String.length(current_chain)
      String.length(current_chain) > String.length(score_chain) ->
        check_chains(recipes, elf_one, elf_two, String.slice(current_chain, 1..-1), score_chain)
      true ->
        create_recipes_until(recipes, elf_one, elf_two, current_chain, score_chain)
    end
  end

  defp create_recipes_until(recipes, elf_one, elf_two, current_chain, score_chain) do
    pre_count = map_size(recipes)

    {new_recipes, created, new_current_chain} =
      case combine_recipes(recipes[elf_one], recipes[elf_two]) do
        [one] ->
          new_recipes = recipes |> Map.put(pre_count, one)
          {new_recipes, 1, String.slice(current_chain, 1..-1) <> "#{one}"}

        [one, two] ->
          new_recipes = recipes |> Map.put(pre_count, one) |> Map.put(pre_count + 1, two)
          {new_recipes, 2, String.slice(current_chain, 1..-1) <> "#{one}#{two}"}
      end

    post_count = pre_count + created
    new_elf_one = rem(elf_one + 1 + recipes[elf_one], post_count)
    new_elf_two = rem(elf_two + 1 + recipes[elf_two], post_count)
    check_chains(new_recipes, new_elf_one, new_elf_two, new_current_chain, score_chain)
  end

  def part2() do
    create_recipes_until("#{input()}")
  end
end
