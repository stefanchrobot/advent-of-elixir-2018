# Advent of Elixir 2018 - day 1, part 1

## Basic types

We have the usual stuff:
- numbers: `100`, `123.45`
- Unicode strings with interpolation: `"1 + 1 is #{1 + 1}"`
- booleans: `true` and `false`
- missing value: `nil`

Additionally, we've got _atoms_ (Ruby's symbols) - constants that you just use without the need to declare them: `:ok`, `:not_found`, etc. We'll see later how and when atoms are useful.

We've got all the operators that you'd expect. One thing worth noting: you can compare (`==`, `<`, etc.) _any_ two things.

## Basic data structures

- tuples, fixed-size containers for things: `{:ok, 42}`, `{:error, "eh?"}`, `{"position_3d", {10, -20, 15}}`
- lists: `[1, 2, 3]`, `[:ok, nil, true, [1, "2", 3]]`
- keyword lists, just a syntactic sugar: `[a: 1, b: "thing"]` is just `[{:a, 1}, {:b, "thing"}]`
- maps (dictionary, hash): `%{"a" => "A", 3 => nil}`, or if you use atom keys: `%{a: 1, b: "thing"}`
- ranges, inclusive: `1..5`

## Immutability

All data is immutable, which means you can't modify a data structure, you need to build a new one from scratch or based on something existing. We do have "variables": you can _rebind_ a variable, but you can't modify the data it points to:

```
x = [1, 2, 3]    # declare x and make it point to [1, 2, 3]
x = [4, 2, 3]    # rebind x, now it points to [4, 2, 3]
```

```
x[0] = 4         # Sorry, you can't do it this way. Easy concurrency or mutability, pick one.
```

## Everything is an expression

There are no statements, everything evaluates to some value, for example:

Nope:
```
x = nil
if z > 5 do
  IO.puts("z is my thing")
  x = z
else
  x = 1
end
```

YES!
```
x =
  if z > 5 do
    IO.puts("z is my thing")
    z
  else
    1
  end
```

## Modules and functions

The only way to organize code in Elixir is to write functions and group them into modules. For example:

```
defmodule Hello do
  def world() do                # Coming from Ruby? Remember about the "do".
    "Advent of Elixir 2018"     # No "return" - the last expression is the result of the function.
  end

  def print_hello do            # You can skip () for functions with no args.
    IO.puts(world())            # Calls "puts" from the "IO" module and "world" from the current module.
  end
end
```

Functions from the `Kernel` module are imported by default:

```
iex> min(5, 7)                 # This is just Kernel.min(5, 7)`
iex> 5 + 7                     # It's really Kernel.+(5, 7)
```

## Naming (casing) convention

It's `CamelCaseModule`, `snake_case_function` and `snake_case_variable`.

## Anonymous functions

They can be captured in variables and passed around. To call a function captured in a variable, you need to use the `.`:

```
iex> add = fn x, y -> x + y end   # I take x and y and return the sum.
iex> add.(1, 2)                   # You need to get used to the dot.
```

## Enumerables

By default, lists, maps and ranges are _enumerable_ (more precisely: they implement the `Enumerable` _protocol_). This means that they can be used with all the functions in the `Enum` module. For example:

```
iex> Enum.find([3, 7, 2, 11, 8], fn x -> x > 10 end)    # 11
iex> Enum.join(1..3, "-")                               # "1-2-3"
```

Note: in IEx you can use TAB for autocompletion. For example, type `Enum.` and press TAB to see all the functions in the `Enum` module. You can read the docs and examples by calling the `h` helper, that is: `h Enum.join`.

The `Enum` module is going to be one of your main workhorses.

## The puzzle

- sign-in to https://adventofcode.com/
- get your input and paste it into [`day01_input.txt`](day011_input.txt)
- [`day01_starter.exs`](day01_starter.exs) has a pre-defined `input` function that reads the input file and returns a list of numbers

You can either use this in IEx:

```
iex> c "day1.exs"
iex> inp = Day1.input()
```

or write the code in the file and run it:

`elixir day1.exs`
