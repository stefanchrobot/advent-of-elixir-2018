defmodule Day16 do
  @doc """
  Parses a captured sample.

      iex> Day16.parse_sample(\"""
      ...> Before: [3, 2, 1, 1]
      ...> 9 2 1 2
      ...> After:  [3, 2, 2, 1]
      ...> \""")
      {{3, 2, 1, 1}, {9, 2, 1, 2}, {3, 2, 2, 1}}
  """
  def parse_sample(string) do
    [before_str, instruction_str, after_str] = String.split(string, "\n", trim: true)

    memory_before =
      before_str
      |> String.split(["Before: [", ", ", "]"], trim: true)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    instruction =
      instruction_str
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    memory_after =
      after_str
      |> String.split(["After:  [", ", ", "]"], trim: true)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    {memory_before, instruction, memory_after}
  end

  @doc """
  Parses the input.

      iex> {samples, program} = Day16.parse_input(\"""
      ...> Before: [3, 0, 2, 1]
      ...> 15 3 2 0
      ...> After:  [1, 0, 2, 1]
      ...>
      ...> Before: [1, 1, 1, 1]
      ...> 6 1 0 1
      ...> After:  [1, 1, 1, 1]
      ...>
      ...>
      ...>
      ...> 1 2 3 0
      ...> 1 0 0 3
      ...> 0 2 0 2
      ...> \""")
      iex> length(samples)
      2
      iex> hd(samples)
      {{3, 0, 2, 1}, {15, 3, 2, 0}, {1, 0, 2, 1}}
      iex> length(program)
      3
      iex> hd(program)
      {1, 2, 3, 0}
  """
  def parse_input(string) do
    [samples_str, program_str] = String.split(string, "\n\n\n\n", trim: true)

    samples =
      samples_str
      |> String.split("\n\n", trim: true)
      |> Enum.map(&parse_sample/1)

    program =
      program_str
      |> String.split("\n", trim: true)
      |> Enum.map(fn line ->
        line
        |> String.split(" ", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end)

    {samples, program}
  end

  @doc """
  Returns the list of all the opcodes.

      iex> Day16.opcodes() |> length()
      16
  """
  def opcodes() do
    [
      :addr,
      :addi,
      :mulr,
      :muli,
      :banr,
      :bani,
      :borr,
      :bori,
      :setr,
      :seti,
      :gtir,
      :gtri,
      :gtrr,
      :eqir,
      :eqri,
      :eqrr
    ]
  end

  @doc """
  Executes the specified instruction given the memory state.

      iex> Day16.execute({10, 20, 30, 40}, {:addr, 0, 1, 3})
      {10, 20, 30, 30}

      iex> Day16.execute({10, 20, 30, 40}, {:addi, 0, 10, 3})
      {10, 20, 30, 20}

      iex> Day16.execute({10, 20, 30, 40}, {:mulr, 0, 1, 3})
      {10, 20, 30, 200}

      iex> Day16.execute({10, 20, 30, 40}, {:muli, 0, 10, 3})
      {10, 20, 30, 100}

      iex> Day16.execute({2, 3, 0, 0}, {:banr, 0, 1, 3})
      {2, 3, 0, 2}

      iex> Day16.execute({2, 3, 0, 0}, {:bani, 0, 6, 3})
      {2, 3, 0, 2}

      iex> Day16.execute({2, 3, 0, 0}, {:borr, 0, 1, 3})
      {2, 3, 0, 3}

      iex> Day16.execute({2, 3, 0, 0}, {:bori, 0, 6, 3})
      {2, 3, 0, 6}

      iex> Day16.execute({10, 20, 30, 40}, {:setr, 0, 2, 3})
      {10, 20, 30, 10}

      iex> Day16.execute({10, 20, 30, 40}, {:seti, 10, 1, 3})
      {10, 20, 30, 10}

      iex> Day16.execute({10, 20, 30, 40}, {:gtir, 20, 0, 3})
      {10, 20, 30, 1}

      iex> Day16.execute({10, 20, 30, 40}, {:gtri, 0, 5, 3})
      {10, 20, 30, 1}

      iex> Day16.execute({10, 20, 30, 40}, {:gtrr, 1, 0, 3})
      {10, 20, 30, 1}

      iex> Day16.execute({10, 20, 30, 40}, {:eqir, 10, 0, 3})
      {10, 20, 30, 1}

      iex> Day16.execute({10, 20, 30, 40}, {:eqri, 0, 20, 3})
      {10, 20, 30, 0}

      iex> Day16.execute({10, 20, 30, 40}, {:eqrr, 0, 1, 3})
      {10, 20, 30, 0}
  """
  def execute(memory, {opcode, a, b, c}) do
    import Bitwise

    case opcode do
      :addr -> putr(memory, c, getr(memory, a) + getr(memory, b))
      :addi -> putr(memory, c, getr(memory, a) + b)
      :mulr -> putr(memory, c, getr(memory, a) * getr(memory, b))
      :muli -> putr(memory, c, getr(memory, a) * b)
      :banr -> putr(memory, c, band(getr(memory, a), getr(memory, b)))
      :bani -> putr(memory, c, band(getr(memory, a), b))
      :borr -> putr(memory, c, bor(getr(memory, a), getr(memory, b)))
      :bori -> putr(memory, c, bor(getr(memory, a), b))
      :setr -> putr(memory, c, getr(memory, a))
      :seti -> putr(memory, c, a)
      :gtir -> putr(memory, c, to_flag(a > getr(memory, b)))
      :gtri -> putr(memory, c, to_flag(getr(memory, a) > b))
      :gtrr -> putr(memory, c, to_flag(getr(memory, a) > getr(memory, b)))
      :eqir -> putr(memory, c, to_flag(a == getr(memory, b)))
      :eqri -> putr(memory, c, to_flag(getr(memory, a) == b))
      :eqrr -> putr(memory, c, to_flag(getr(memory, a) == getr(memory, b)))
    end
  end

  defp getr({r0, r1, r2, r3}, r) do
    case r do
      0 -> r0
      1 -> r1
      2 -> r2
      3 -> r3
    end
  end

  defp putr({r0, r1, r2, r3}, r, value) do
    case r do
      0 -> {value, r1, r2, r3}
      1 -> {r0, value, r2, r3}
      2 -> {r0, r1, value, r3}
      3 -> {r0, r1, r2, value}
    end
  end

  defp to_flag(condition) do
    if condition, do: 1, else: 0
  end

  @doc """
  Returns the list of opcodes that match the instruction given the sample.

      iex> sample = Day16.parse_sample(\"""
      ...> Before: [3, 2, 1, 1]
      ...> 9 2 1 2
      ...> After:  [3, 2, 2, 1]
      ...> \""")
      iex> Day16.matched_opcodes(sample) |> Enum.sort()
      [:addi, :mulr, :seti]
  """
  def matched_opcodes({memory_before, {_, a, b, c}, memory_after}) do
    Enum.filter(opcodes(), fn opcode ->
      execute(memory_before, {opcode, a, b, c}) == memory_after
    end)
  end

  @doc """
  Returns the count of samples that behave like at least `count` opcodes.

      iex> sample = Day16.parse_sample(\"""
      ...> Before: [3, 2, 1, 1]
      ...> 9 2 1 2
      ...> After:  [3, 2, 2, 1]
      ...> \""")
      iex> Day16.behave_like_at_least([sample], 2)
      1
  """
  def behave_like_at_least(samples, count) do
    Enum.count(samples, fn sample -> length(matched_opcodes(sample)) >= count end)
  end

  def input() do
    "day16_input.txt"
    |> File.read!()
    |> parse_input()
  end

  def part1() do
    {samples, _program} = input()
    behave_like_at_least(samples, 3)
  end

  @doc """
  Matches the numbers to opcodes. Returns the mapping or `:ambiguous_samples`.
  """
  def match_numbers_to_opcodes(samples) do
    Enum.reduce(samples, %{}, fn sample, number_to_codes ->
      {_memory_before, {number, _a, _b, _c}, _memory_after} = sample
      matched_opcodes = matched_opcodes(sample) |> MapSet.new()
      Map.update(number_to_codes, number, matched_opcodes, &MapSet.union(&1, matched_opcodes))
    end)
    |> derive_matching(%{})
  end

  defp derive_matching(number_to_codes, matching) when map_size(number_to_codes) == 0 do
    matching
  end

  defp derive_matching(number_to_codes, matching) do
    case Enum.find(number_to_codes, fn {_number, codes} -> MapSet.size(codes) == 1 end) do
      nil ->
        :ambiguous_samples

      {number, codes} ->
        matched_code = Enum.at(codes, 0)

        number_to_codes
        |> Enum.map(fn {number, codes} -> {number, MapSet.delete(codes, matched_code)} end)
        |> Enum.into(%{})
        |> Map.delete(number)
        |> derive_matching(Map.put(matching, number, matched_code))
    end
  end

  @doc """
  Executes the program. Returns the resulting memory.

      # iex> program = [
      # ...>   {1, 2, 3, 0},
      # ...>   {1, 0, 0, 3},
      # ...>   {0, 2, 0, 2}
      # ...> ]
      # iex> matching = %{0 => :addr, 1 => :addi}
      # iex> Day16.execute_program(program, matching)
      # {3, 0, 3, 0}
  """
  def execute_program(program, matching) do
    Enum.reduce(program, {0, 0, 0, 0}, fn {number, a, b, c}, memory ->
      execute(memory, {matching[number], a, b, c})
    end)
  end

  def part2() do
    {samples, program} = input()
    matching = match_numbers_to_opcodes(samples)
    execute_program(program, matching)
  end
end
