defmodule Day19 do
  @doc """
  Parses the program.

      iex> Day19.parse_program(\"""
      ...> #ip 0
      ...> seti 5 0 1
      ...> seti 6 0 2
      ...> addi 0 1 0
      ...> \""")
      {0, %{0 => {:seti, 5, 0, 1}, 1 => {:seti, 6, 0, 2}, 2 => {:addi, 0, 1, 0}}}
  """
  def parse_program(string) do
    [<<"#ip ", ip_binding::binary>> | instructions_str] = String.split(string, "\n", trim: true)

    instructions =
      instructions_str
      |> Enum.map(fn line ->
        {:ok, instruction} = parse_instruction(line)
        instruction
      end)
      |> Enum.with_index()
      |> Enum.map(fn {instruction, index} -> {index, instruction} end)
      |> Enum.into(%{})

    {String.to_integer(ip_binding), instructions}
  end

  def parse_instruction(string) do
    try do
      [opcode, a, b, c] = String.split(string, " ", trim: true)

      {:ok,
       {
         String.to_existing_atom(opcode),
         String.to_integer(a),
         String.to_integer(b),
         String.to_integer(c)
       }}
    rescue
      _ -> :error
    end
  end

  @doc """
  Returns the list of all the opcodes.

      iex> Day19.opcodes() |> length()
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

      iex> Day19.execute({10, 20, 30, 40}, {:addr, 0, 1, 3})
      {10, 20, 30, 30}

      iex> Day19.execute({10, 20, 30, 40}, {:addi, 0, 10, 3})
      {10, 20, 30, 20}

      iex> Day19.execute({10, 20, 30, 40}, {:mulr, 0, 1, 3})
      {10, 20, 30, 200}

      iex> Day19.execute({10, 20, 30, 40}, {:muli, 0, 10, 3})
      {10, 20, 30, 100}

      iex> Day19.execute({2, 3, 0, 0}, {:banr, 0, 1, 3})
      {2, 3, 0, 2}

      iex> Day19.execute({2, 3, 0, 0}, {:bani, 0, 6, 3})
      {2, 3, 0, 2}

      iex> Day19.execute({2, 3, 0, 0}, {:borr, 0, 1, 3})
      {2, 3, 0, 3}

      iex> Day19.execute({2, 3, 0, 0}, {:bori, 0, 6, 3})
      {2, 3, 0, 6}

      iex> Day19.execute({10, 20, 30, 40}, {:setr, 0, 2, 3})
      {10, 20, 30, 10}

      iex> Day19.execute({10, 20, 30, 40}, {:seti, 10, 1, 3})
      {10, 20, 30, 10}

      iex> Day19.execute({10, 20, 30, 40}, {:gtir, 20, 0, 3})
      {10, 20, 30, 1}

      iex> Day19.execute({10, 20, 30, 40}, {:gtri, 0, 5, 3})
      {10, 20, 30, 1}

      iex> Day19.execute({10, 20, 30, 40}, {:gtrr, 1, 0, 3})
      {10, 20, 30, 1}

      iex> Day19.execute({10, 20, 30, 40}, {:eqir, 10, 0, 3})
      {10, 20, 30, 1}

      iex> Day19.execute({10, 20, 30, 40}, {:eqri, 0, 20, 3})
      {10, 20, 30, 0}

      iex> Day19.execute({10, 20, 30, 40}, {:eqrr, 0, 1, 3})
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

  defp getr(memory, r) do
    elem(memory, r)
  end

  defp putr(memory, r, value) do
    put_elem(memory, r, value)
  end

  defp to_flag(condition) do
    if condition, do: 1, else: 0
  end

  @doc """
  Executes the program. Returns the resulting memory.

      iex> Day19.parse_program(\"""
      ...> #ip 0
      ...> seti 5 0 1
      ...> seti 6 0 2
      ...> addi 0 1 0
      ...> addr 1 2 3
      ...> setr 1 0 0
      ...> seti 8 0 4
      ...> seti 9 0 5
      ...> \""") |> Day19.execute_program()
      {6, 5, 6, 0, 0, 9}
  """
  def execute_program(program, memory \\ {0, 0, 0, 0, 0, 0}) do
    case step_program(program, memory) do
      {:cont, next_memory} -> execute_program(program, next_memory)
      {:halt, next_memory} -> next_memory
    end
  end

  def step_program({ip_binding, instructions}, memory, opts \\ [debug: false]) do
    ip = getr(memory, ip_binding)
    instruction = instructions[ip]
    next_memory = execute(memory, instruction)
    print_state(ip, memory, instruction, next_memory, opts)
    next_ip = getr(next_memory, ip_binding) + 1

    if Map.has_key?(instructions, next_ip) do
      {:cont, putr(next_memory, ip_binding, next_ip)}
    else
      {:halt, next_memory}
    end
  end

  def print_state(ip, memory, instruction, next_memory, opts) do
    if opts[:debug] do
      memory_str = memory |> Tuple.to_list() |> Enum.join(", ")
      instruction_str = instruction |> Tuple.to_list() |> Enum.join(" ")
      next_memory_str = next_memory |> Tuple.to_list() |> Enum.join(", ")
      IO.puts("ip=#{ip} [#{memory_str}] #{instruction_str} [#{next_memory_str}]")
    end
  end

  def input() do
    "day19_input.txt"
    |> File.read!()
    |> parse_program()
  end

  def part1() do
    input() |> execute_program()
  end

  def clear_screen() do
    IO.write([IO.ANSI.home(), IO.ANSI.clear()])
  end

  def debug_program(program, memory) do
    clear_screen()
    IO.puts("Interactive debugger running. Type \"help\" for help.\n")
    print_program_and_memory(program, memory)

    case IO.gets("# ") |> String.trim("\n") do
      "stop" ->
        memory

      "help" ->
        print_help()
        debug_program(program, memory)

      "" ->
        {state, next_memory} = step_program(program, memory)

        if state == :halt do
          IO.puts("Program halted.")
          memory
        else
          debug_program(program, next_memory)
        end

      instruction_command ->
        case instruction_command |> parse_instruction() do
          {:ok, instruction} ->
            debug_program(program, execute(memory, instruction))

          :error ->
            IO.puts("Invalid instruction. Press [Enter] to continue.")
            IO.gets("")
        end
    end
  end

  defp print_program_and_memory({ip_binding, instructions}, memory) do
    ip = getr(memory, ip_binding)

    instructions
    |> Enum.sort_by(fn {index, _instruction} -> index end)
    |> Enum.map(&format_instruction(&1, ip_binding, ip))
    |> Enum.join("\n")
    |> IO.puts()

    IO.puts("\n")

    0..5
    |> Enum.map(fn reg ->
      reg
      |> register_name(ip_binding)
      |> Kernel.<>(" (#{reg})")
      |> String.pad_leading(10)
    end)
    |> Enum.join()
    |> IO.puts()

    0..5
    |> Enum.map(fn reg ->
      getr(memory, reg)
      |> to_string()
      |> String.pad_leading(10)
    end)
    |> Enum.join()
    |> IO.puts()

    IO.puts("\n")
  end

  defp print_help() do
    clear_screen()

    IO.puts("""
    Help

    * Press [Enter] to continue execution.
    * Type "stop" to terminate the debugging session.
    * Type an instruction to execute it, e.g. "addi 1 2 4"
    * Type "help" to show this screen.

    Press [Enter] to continue.
    """)

    IO.gets("")
  end

  defp format_instruction({index, {opcode, a, b, c} = instruction}, ip_binding, ip) do
    reg = fn reg -> register_name(reg, ip_binding) end

    source =
      case opcode do
        :addr -> "#{reg.(c)} = #{reg.(a)} + #{reg.(b)}"
        :addi -> "#{reg.(c)} = #{reg.(a)} + #{b}"
        :mulr -> "#{reg.(c)} = #{reg.(a)} * #{reg.(b)}"
        :muli -> "#{reg.(c)} = #{reg.(a)} * #{b}"
        :banr -> "#{reg.(c)} = #{reg.(a)} & #{reg.(b)}"
        :bani -> "#{reg.(c)} = #{reg.(a)} & #{b}"
        :borr -> "#{reg.(c)} = #{reg.(a)} | #{reg.(b)}"
        :bori -> "#{reg.(c)} = #{reg.(a)} | #{b}"
        :setr -> "#{reg.(c)} = #{reg.(a)}"
        :seti -> "#{reg.(c)} = #{a}"
        :gtir -> "#{reg.(c)} = #{a} > #{reg.(b)}"
        :gtri -> "#{reg.(c)} = #{reg.(a)} > #{b}"
        :gtrr -> "#{reg.(c)} = #{reg.(a)} > #{reg.(b)}"
        :eqir -> "#{reg.(c)} = #{a} == #{reg.(b)}"
        :eqri -> "#{reg.(c)} = #{reg.(a)} == #{b}"
        :eqrr -> "#{reg.(c)} = #{reg.(a)} == #{reg.(b)}"
      end
      |> String.pad_trailing(39)

    ip_marker = if index == ip, do: ">>", else: "  "
    index_str = index |> to_string |> String.pad_leading(2)

    instruction_str =
      instruction
      |> Tuple.to_list()
      |> Enum.map(fn item ->
        item
        |> to_string()
        |> String.pad_leading(2)
      end)
      |> Enum.join(" ")

    "#{ip_marker} #{index_str}: #{source} #{instruction_str}"
  end

  defp register_name(r, ip_binding) do
    if r == ip_binding do
      "IP"
    else
      <<?A + r>>
    end
  end

  def part2_manual() do
    # Use "seti 10 0 5" after few steps to figure out
    # what the program is doing.
    debug_program(input(), {1, 0, 0, 0, 0, 0})
  end

  def divisor_sum(n) do
    1..n
    |> Enum.filter(fn x -> rem(n, x) == 0 end)
    |> Enum.sum()
  end

  def part2() do
    # The 6th register after few initial instructions.
    f_reg = 10_551_350
    divisor_sum(f_reg)
  end
end
