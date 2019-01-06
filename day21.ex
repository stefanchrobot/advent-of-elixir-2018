defmodule Day21 do
  @doc """
  Parses the program.

      iex> Day21.parse_program(\"""
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

      iex> Day21.opcodes() |> length()
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

      iex> Day21.execute({10, 20, 30, 40}, {:addr, 0, 1, 3})
      {10, 20, 30, 30}

      iex> Day21.execute({10, 20, 30, 40}, {:addi, 0, 10, 3})
      {10, 20, 30, 20}

      iex> Day21.execute({10, 20, 30, 40}, {:mulr, 0, 1, 3})
      {10, 20, 30, 200}

      iex> Day21.execute({10, 20, 30, 40}, {:muli, 0, 10, 3})
      {10, 20, 30, 100}

      iex> Day21.execute({2, 3, 0, 0}, {:banr, 0, 1, 3})
      {2, 3, 0, 2}

      iex> Day21.execute({2, 3, 0, 0}, {:bani, 0, 6, 3})
      {2, 3, 0, 2}

      iex> Day21.execute({2, 3, 0, 0}, {:borr, 0, 1, 3})
      {2, 3, 0, 3}

      iex> Day21.execute({2, 3, 0, 0}, {:bori, 0, 6, 3})
      {2, 3, 0, 6}

      iex> Day21.execute({10, 20, 30, 40}, {:setr, 0, 2, 3})
      {10, 20, 30, 10}

      iex> Day21.execute({10, 20, 30, 40}, {:seti, 10, 1, 3})
      {10, 20, 30, 10}

      iex> Day21.execute({10, 20, 30, 40}, {:gtir, 20, 0, 3})
      {10, 20, 30, 1}

      iex> Day21.execute({10, 20, 30, 40}, {:gtri, 0, 5, 3})
      {10, 20, 30, 1}

      iex> Day21.execute({10, 20, 30, 40}, {:gtrr, 1, 0, 3})
      {10, 20, 30, 1}

      iex> Day21.execute({10, 20, 30, 40}, {:eqir, 10, 0, 3})
      {10, 20, 30, 1}

      iex> Day21.execute({10, 20, 30, 40}, {:eqri, 0, 20, 3})
      {10, 20, 30, 0}

      iex> Day21.execute({10, 20, 30, 40}, {:eqrr, 0, 1, 3})
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

      iex> Day21.parse_program(\"""
      ...> #ip 0
      ...> seti 5 0 1
      ...> seti 6 0 2
      ...> addi 0 1 0
      ...> addr 1 2 3
      ...> setr 1 0 0
      ...> seti 8 0 4
      ...> seti 9 0 5
      ...> \""") |> Day21.execute_program()
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
    "day21_input.txt"
    |> File.read!()
    |> parse_program()
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
            debug_program(program, memory)
        end
    end
  end

  defp print_program_and_memory({ip_binding, instructions}, memory) do
    ip = getr(memory, ip_binding)

    instructions = Enum.sort_by(instructions, fn {index, _instruction} -> index end)

    instructions
    |> Enum.map(&format_instruction(&1, ip_binding, ip, instructions))
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

  defp format_instruction({index, instruction}, ip_binding, ip, instructions) do
    source =
      instruction
      |> decompile(index, ip_binding, instructions)
      |> String.pad_trailing(30)

    ip_marker = if index == ip, do: ">>", else: "  "
    index_str = index |> to_string |> String.pad_leading(2)

    instruction_str =
      instruction
      |> Tuple.to_list()
      |> Enum.map(fn item ->
        item
        |> to_string()
        |> String.pad_leading(8)
      end)
      |> Enum.join(" ")

    "#{ip_marker} #{index_str}: #{source} #{instruction_str}"
  end

  defp decompile({opcode, a, b, c}, index, ip_binding, instructions) do
    previous_instruction = Enum.find(instructions, fn {idx, _instruction} -> idx == index - 1 end)

    cond do
      if_then?({opcode, a, b, c}, index, ip_binding, instructions) ->
        condition =
          basic_decompile({opcode, a, b, c}, ip_binding) |> String.split(" = ") |> Enum.at(1)

        "IF (#{condition}) [#{register_name(c, ip_binding)}]"

      previous_instruction != nil &&
          if_then?(
            elem(previous_instruction, 1),
            elem(previous_instruction, 0),
            ip_binding,
            instructions
          ) ->
        "THEN GOTO #{index + 2} ELSE GOTO #{index + 1}"

      opcode == :seti and c == ip_binding ->
        "GOTO #{a + 1}"

      opcode == :addi and a == ip_binding and c == ip_binding ->
        "GOTO #{index + b + 1}"

      true ->
        basic_decompile({opcode, a, b, c}, ip_binding)
    end
  end

  defp basic_decompile({opcode, a, b, c}, ip_binding) do
    reg = fn reg -> register_name(reg, ip_binding) end

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
  end

  defp if_then?({opcode, _a, _b, c}, index, ip_binding, instructions) do
    opcode in [:gtir, :gtri, :gtrr, :eqir, :eqri, :eqrr] &&
      Enum.any?(instructions, fn instruction ->
        instruction == {index + 1, {:addr, c, ip_binding, ip_binding}}
      end)
  end

  defp register_name(r, ip_binding) do
    if r == ip_binding do
      "IP"
    else
      <<?A + r>>
    end
  end

  def part1() do
    # Step through until the program reaches the loop with "18: C = F + 1",
    # make a shortcut with "seti 255 0 5" and step through program till
    # the program reaches "28: IF (B == A) [F]".
    debug_program(input(), {0, 0, 0, 0, 0, 0})
  end

  # The decompiled program:
  #
  # CHECK_BINARY_OPS()
  #
  # B = 0
  # E = B | 1_0000_0000_0000_0000_b
  # B = 0011_1001_1111_0111_0011_0111_b
  #
  # WHILE TRUE:
  #   B = CALC_B(B, E & 255)
  #
  #   IF (E <= 1111_1111_b) AND (B == A):
  #     RETURN
  #
  #   IF (E <= 1111_1111_b):
  #     E = B | 1_0000_0000_0000_0000_b
  #     B = 0011_1001_1111_0111_0011_0111_b
  #   ELSE:
  #     E = E >> 8  # SHIFT_RIGHT_8(E)
  #
  #
  # CALC_B(B, X):
  #   B = B + X
  #   B = B & 1111_1111_1111_1111_1111_1111_b
  #   B = B * 65899
  #   B = B & 1111_1111_1111_1111_1111_1111_b
  #   RETURN B
  #
  #
  # SHIFT_RIGHT_8(X):
  #   # INTEGER DIVISION BY 256
  #   F = 0
  #   WHILE TRUE:
  #     C = F + 1
  #     C = C * 256
  #     IF (C > X):
  #       RETURN F
  #     ELSE:
  #       F = F + 1
  #
  #
  # CHECK_BINARY_OPS():
  #   B = 123
  #   WHILE TRUE:
  #     B = B & 456
  #     IF B == 72:
  #       BREAK
  #

  import Bitwise

  def mystery_function({b, e, _}) do
    b = calc_b(b, band(e, 255))
    if e < 256 do
      {3798839, bor(b, 65536), b}
    else
      {b, e >>> 8, :cont}
    end
  end

  defp calc_b(b, x) do
    b = b + x
    b = band(b, 16777215)
    b = b * 65899
    b = band(b, 16777215)
    b
  end

  def part2() do
    # Run the program and keep all values that are checked in the halting
    # condition. The value that we're looking for is the last one before
    # they start repeating.
    {3798839, 65536, :cont}
    |> Stream.unfold(fn state -> {state, mystery_function(state)} end)
    |> Stream.filter(fn {_, _, value} -> value != :cont end)
    |> Stream.map(fn {_, _, value} -> value end)
    |> Enum.reduce_while([], fn x, seen ->
      if x in seen do
        {:halt, hd(seen)}
      else
        {:cont, [x | seen]}
      end
    end)
  end
end
