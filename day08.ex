defmodule Day08 do
  def example() do
    "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2"
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  def input() do
    "day08_input.txt"
    |> File.read!()
    |> String.trim()
    |> String.split(" ", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  @doc """
  Builds the tree from the description.

      iex> Day08.build_tree([0, 3, 1, 2, 3])
      {[], [1, 2, 3]}

      iex> Day08.build_tree([1, 1, 0, 1, 2, 3])
      {[{[], [2]}], [3]}
  """
  def build_tree(description) do
    {root_node, []} = build_node(description)
    root_node
  end

  defp build_node(description) do
    [child_count, metadata_count | rest] = description
    {children, rest} = build_children([], rest, child_count)
    {metadata, rest} = Enum.split(rest, metadata_count)
    {{children, metadata}, rest}
  end

  defp build_children(children, description, 0) do
    {Enum.reverse(children), description}
  end

  defp build_children(children, description, count) do
    {child, rest} = build_node(description)
    build_children([child | children], rest, count - 1)
  end

  @doc """
  Returns the sum of all the metadata in the tree.

      iex> Day08.sum_metadata({[{[], [10, 11, 12]}, {[{[], [99]}], [2]}], [1, 1, 2]})
      138
  """
  def sum_metadata({children, metadata}) do
    subsum =
      children
      |> Enum.map(&sum_metadata/1)
      |> Enum.sum()

    Enum.sum(metadata) + subsum
  end

  def part1() do
    input()
    |> build_tree()
    |> sum_metadata()
  end

  @doc """
  Calculates the value of the node.

      iex> Day08.node_value({[{[], [10, 11, 12]}, {[{[], [99]}], [2]}], [1, 1, 2]})
      66
  """
  def node_value({[], metadata}) do
    Enum.sum(metadata)
  end

  def node_value({children, metadata}) do
    indexed_children =
      children
      |> Enum.with_index(1)
      |> Enum.map(fn {node, index} -> {index, node} end)
      |> Enum.into(%{})

    children_count = length(children)

    metadata
    |> Enum.filter(fn index -> index >= 1 and index <= children_count end)
    |> Enum.map(fn index -> node_value(indexed_children[index]) end)
    |> Enum.sum()
  end

  def part2() do
    input()
    |> build_tree()
    |> node_value()
  end

  def print_tree(tree) do
    print_tree(tree, "")
  end

  defp print_tree({children, metadata}, indent) do
    IO.puts("#{indent}* #{Enum.join(metadata, "-")}")
    Enum.each(children, &print_tree(&1, indent <> "  "))
  end
end
