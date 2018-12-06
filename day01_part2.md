# Advent of Elixir 2018 - day 1, part 2

## Enum.sum

Part 1 was as easy as `Enum.sum(input())`. But let's understand how `Enum.sum` is implemented. We'll be taking small steps and I'll try to introduce one concept at a time.

## No loops, no problem

There are no loops in Elixir; the only other option is recursion: a function has to call itself. Classic Fibonacci:

```
defmodule Sequence do
  def fib(n) do
    if n < 3 do
      1
    else
      fib(n - 2) + fib(n - 1)
    end
  end
end

iex> Enum.map(1..10, fn n -> Sequence.fib(n) end)
```

Note: anonymous functions cannot call themselves.

## Recursive sum

Definition:

- `sum([]) == 0`
- `sum([x, y, z, ...]) == x + sum([y, z, ...])`

Implementation:

```
defmodule MyEnum do
  def sum(list) do
    if list == [] do
      0
    else
      head = hd(list)     # hd([1, 2, 3]) == 1
      tail = tl(list)     # tl([1, 2, 3]) == [2, 3], tl([1]) == []
      head + sum(tail)    # stack overflow if list too long...?
    end
  end
end
```

## Enter the accumulator

The Erlang runtime can do tail-call optimization: if the last thing you do is call yourself, the recursion will be turned into iteration underneath. The example above is not tail-recursive, because we do something along the lines of:

```
# ...
subsum = sum(tail)
Kernel.+(head, subsum)
```

A common pattern for this problem is the accumulator - an extra function argument for keeping "the state so far":

```
defmodule MyEnum do
  def sum(list) do              # let's keep the accumulator out of the public API
    do_sum(list, 0)
  end

  defp do_sum(list, acc) do     # "acc" keeps the sum so far; "defp" means "private to this module"
    if list == [] do
      acc
    else
      head = hd(list)
      tail = tl(list)
      do_sum(tail, acc + head)  # tail-recursive, yay!
    end
  end
end
```

`do_sum` is way too long. Don't worry, we'll get down to 2 lines eventually.

## Generalising the sum

What if we want a product (x * y * z * ...)? We'd have to change the operation from `+` to `*` and the initial value from `0` to `1`. Let's customize this by passing extra args:

```
defmodule MyEnum do
  def process(list, acc, operation) do    # "acc" is in our API this time, caller provides the initial value
    if list == [] do
      acc
    else
      head = hd(list)
      tail = tl(list)
      next_acc = operation.(head, acc)
      process(tail, next_acc, operation)
    end
  end
end
```

With `process` at our disposal, `sum` and `product` can be simply this:

```
MyEnum.process(list, 0, fn x, acc -> x + acc end)     # sum
MyEnum.process(list, 1, fn x, acc -> x * acc end)     # product
```

Our `process` is actually `Enum.reduce` - one of the fundamental functions in functional programming (also known as `fold` elsewhere). Most functions in `Enum` _can be implemented in terms of_ `reduce`.

## Meet Stream, the lazy Enum

All the functions in `Enum` are eager, which means they traverse the enumarable straight away. That's not always desirable, especially if you work with huge or infinite inputs (files, sockets, etc.). We'll get back to `Stream` later, but the useful thing to know for now is the module provides functions for generating infinite collections, for example:

```
iex> stream = Stream.repeatedly(fn -> :rand.uniform() end)   # I can generate stuff all day long.
iex> Enum.take(stream, 5)                                    # List of 5 random numbers.
```

## The puzzle

The input for the second part is the same. Here are some tips for solving the puzzle:

- if you need a set data structure, you can use `MapSet` like so:

```
iex> s = MapSet.new()         # It's based on the Map data structure.
iex> s = MapSet.put(s, 1)     # Immutability, I need to rebind s to the updated set.
iex> 1 in s                   # Checking membership.
```

- use `elem` to get elements from a tuple, like so `elem({:a, 1}, 0) == :a`
- check the docs for `Enum.reduce` and it's variants to see if it might be useful for solving the puzzle
