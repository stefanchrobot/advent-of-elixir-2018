defmodule Day1 do
  def input do
    # You'll soon learn how to write this better.
    content = File.read!("day1_input.txt")
    Enum.map(String.split(content), fn x -> String.to_integer(x) end)
  end

  def part1 do
    # TODO: Your implementation, use input() somehow.
    42
  end
end

# IO.puts("The answer is #{Day1.part1()}")
