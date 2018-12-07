# Advent of Elixir 2018 - day 4

## The last few notable language constructs

### unless

The opposite of `if`:

```
unless Enum.sum([2, 2]) == 5 do
  "Math still works"
else
  "Math is broken"
end
```

### cond

More convenient `if`-`else if`-...

```
cond do
  1 + 1 == 1 ->
    "This will never match"
  2 * 2 != 4 ->
    "Nor this"
  true ->
    "This will"
end
```

### for

Comprehensions allow to build a data structure based on enumerable or multiple enumerables:

```
for x <- 1..2, y <- 1..2 do       # generates [{1, 1}, {1, 2}, {2, 1}, {2, 2}]
  {x, y}
end
```

The comprehensions can also do filtering, pattern matching and outputing into different collections (map, etc.). See the docs (`h for`) for more examples.

### with

Consider the scenario of reading from two files:

```
case File.read("one.txt") do
  {:ok, content_one} ->
    case File.read("two.txt") do
      {:ok, content_two} -> process(content_one, content_two)
      {:error, error} -> error
    end
  {:error, error} -> error
end
```

The matching clauses can be combined into one by using `with`:

```
with {:ok, content_one} <- File.read("one.txt"),
     {:ok, content_two} <- File.read("two.txt") do
  process(content_one, content_two)
else                                                  # optional
  {:error, error} -> error
end
```

If all the clauses match, the `do` block is evaluated. Otherwise the chain is aborted and the non-matched value is returned or the `else` block is evaluated (if specified).

### one-liners

```
something do
  ...
end
```

is just a nicer syntax for:

```
something, do: ...
```

So our `sum` function can be rewritten as:

```
defmodule MyEnum do
  # as promised: two lines
  def sum([], total), do: total
  def sum([head | tail], total), do: sum(tail, total + head)
end
```

## Another look at Stream

Let's look at the following pipeline:

```
[
  "#1 @ 935,649: 22x22",
  "#2 @ 346,47: 19x26",
  "#3 @ 218,455: 25x17",
  ...
]
|> Enum.map(&parse_claim/1)
|> Enum.find(&some_condition/1)       # stops at first element that passes "some_condition"
```

The whole initial list will be traversed, even if the element we're looking for is at the beginning of the list. It's because `Enum.map` traverses the whole list immediatelly (it's said to be _eager_). We can fix that by combining the mapping and the filtering into one pass (`Enum.reduce_while` or manual recursion). But there's an easier way: using _lazy_ evalution. What we want is an enumerable that pulls the next element only when it's needed. That's what `Stream` does:

```
[
  "#1 @ 935,649: 22x22",
  "#2 @ 346,47: 19x26",
  "#3 @ 218,455: 25x17",
  ...
]
|> Stream.map(&parse_claim/1)                 # will map next element on demand
|> Enum.find(&some_condition/1)
```

Many functions from the `Enum` module have their `Stream` counterparts, but remember that streams are _slower_ so use them only when needed: when working with big files (see `File.stream!`) or infinite streams (socket, `Stream.cycle`, etc.).

## User-defined types

We can follow the pattern of `Map` and `MapSet` to define our own types:

```
defmodule Box do
  def new(x, y, width, height) do
    %{x: x, y: y, width: width, height: height}         # we could use a tuple or a list here
  end

  def area(%{width: width, height: height}) do          # pattern matching on "width" and "height"
    width * height
  end
end

iex> Box.new(1, 1, 4, 5) |> Box.area()
```

### Structs

For user-defined types based on maps there's a convenient feature called _structs_:

```
defmodule Box do
  defstruct [:x, :y, :width, :height]
end
```

Now we can create a Box using a syntax similar to maps:

```
box = %Box{x: 1, y: 1, width: 4, height: 5}
```

Underneath, struct is just a map with an extra key-value pair:

```
%{__struct__: Box, x: 1, y: 1, width: 4, height: 5} == box

"the width is #{box.width}"             # use it just like a map
%{box | width: 10}                      # update; we can use Map.put as well
```

Structs can be destructured and pattern-matched:

```
%{x: x, y: y} = box                   # matches, box is just a map
%Box{x: x, y: y} = %{x: 1, y: 2}      # will not match, our pattern requires a Box
```

The additional benefit of using structs is that we can implement different _protocols_: make it enumarable, implement "stringification", etc.

Our Box type could look like this:

```
defmodule Box do
  defstruct [:x, :y, :width, :height]

  def new(x, y, width, height) do
    %Box{x: x, y: y, width: width, height: height}
  end

  def area(%Box{width: width, height: height}) do       # we can make this work with Boxes only or any map...
    width * height
  end
end
```

## The puzzle

The puzzle involves handling of time. Just for the exercise, consider defining your own user type for handling that.
