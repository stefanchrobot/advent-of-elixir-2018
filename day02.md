# Advent of Elixir 2018 - day 2

## A closer look at lists

Lists in Elixir are linked lists. List is a pair of value (head) and a pointer to the rest of the list (tail):

```
[1, 2, 3]
```

is in memory (conceptually) represented as:

```
(1, *)
    |
    v
   (2, *)
       |
       v
      (3, *)
          |
          v
          []
```

Elixir has a syntax that mirrors this structure:

```
[head | tail]                   # build a list with head and tail; tail has to be a list

[1 | [2, 3]]                    # head: 1, tail: [2, 3]
[1 | [2 | [3 | []]]]            # builds [1, 2, 3]
```

You can use the `hd` and `tl` functions to get the head and the tail of a list.

Due to the nature of lists, calculating the length and appending requires traversing of the whole list:

```
length([1, 2, 3])     # costly for big lists
[1, 2, 3] ++ [4]      # try to avoid this!
```

On the other hand prepending is very efficient:

```
[4 | list]
```

If you need to build a list, do it by prepending to the list and finish up with calling `Enum.reverse(list)`.

## Destructuring assignment

Immutability means that we need to be able to conveniently create new data structures based on existing ones. Here comes destructuring assignment. The mechanism allows us to destructure data and assign parts of it to variables:

```
point = {10, -15}
{x, y} = point          # x is 10, y is -15

list = [1, 2, 3, 4]
[a, b | rest] = list    # a is 1, b is 2, rest is [3, 4]
[head | tail] = [1]     # head is 1, tail is []
```

You can use destructuring in function heads as well:

```
defmodule Point do
  def to_string({x, y}) do
    IO.puts("#{x},#{y}")
  end
end
```

Thanks to that, we can rewrite our implementation of `process`:

```
defmodule MyEnum do
  def process(list, acc, operation) do
    if list == [] do
      acc
    else
      [head | tail] = list                # here's the change
      next_acc = operation.(head, acc)
      process(tail, next_acc, operation)
    end
  end
end
```

Elixir will warn you about unused variables. You can use `_` to denote unused assignment. Assuming we do something with `x`, but not `y`:

```
{x, y} = {1, 2}     # unused variable "y"
{x, _} = {1, 2}     # fine, no warning
{x, _y} = {1, 2}    # even better, we say that "y" is unused but still say what's the purpose of it
```

## The pipe operator

Another consequence of immutability is that working with data is like sending it through a pipeline or multiple steps that transform the data into something else. While computers have no issues with parsing this:

```
Enum.filter(Enum.map(list, fn x -> String.trim(x) end), fn x -> String.length(x) < 10 end)
```

people are pretty bad at it. The pipe operator to the rescue! The `|>` operator lets us invert the nesting. The following pairs are equivalent:

```
x |> a()                      a(x)

a() |> b(1) |> c()            c(b(a(), 1))
```

The left side is passed as the first argument to the function call on the right. With the pipe our example becomes:

```
list
|> Enum.map(fn x -> String.trim(x) end)
|> Enum.filter(fn x -> String.length(x) < 10 end)
```

## The puzzle

- get your input and paste it into [`day02_input.txt`](day02_input.txt)
- [`day02.exs`](day02.exs) has a pre-defined `input` function that reads the input file and returns a list of strings

Here are some things that you might find useful:

- the `String` module for working with strings, especially:
```
String.codepoints("abc")       # ["a", "b", "c"]
```
- the `Map` module for working with maps
