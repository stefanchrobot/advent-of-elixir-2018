# Advent of Elixir 2018 - day 3

## Working with maps

Maps is _the_ key-value data structure in Elixir. Here are some ways to create, query and update a map:

```
%{}                                   # blank map
Map.new()                             # same thing

%{key => value}                       # key and value can be anything
%{"event" => "Advent of Code"}

m = %{"a" => 1}
m["a"]                                # 1
m["b"]                                # nil

m = Map.put(m, "b", 1)                # set or replace
m = %{m | "b" => 2}                   # replace only, fails if key not in map
```

Note: have a look at the docs for the `Map` module, `Map.update` is especially useful.

Maps have a convenient syntax for atom keys:

```
m = %{a: 1}             # same as %{:a => 1}
m[:a]                   # 1
m.a                     # 1

# but:

m[:b]                   # nil
m.b                     # ** (KeyError) key :b not found in: %{a: 1}
```

Maps can be destructured as well:

```
map = %{name: "john"}

%{name: name} = map         # name is now "john"
```

## The capture operator

To store a reference to a function, you need to use `&` - the capture operator. Since functions in Elixir are uniquely identified by name and arity (number of arguments), this needs to be specified as well:

```
f = &String.upcase/1        # f points to the "upcase" function from the "String" module with arity 1
f.("hello")                 # f is really equivalent to "fn x -> String.upcase(x) end)", less efficient though
```

This is useful when an existing function is "compatible" with a one you need, for example when mapping collections:

```
Enum.map(list, &String.upcase/1)
```

The other use case for the capture operator is to write a more terse version of anonymous functions. The following pairs are equivalent:

```
&(&1 + 7)       # fn x -> x + 7 end
&[&1, &1]       # fn x -> [x, x] end
&(&1 * &2)      # fn x, y -> x * y end
```

`&n` refers to the n-th argument of the function. Use with caution, since this can get cryptic pretty fast (with `fn` the arguments can have a meaningful name).

## Pattern matching - destructuring on steroids

Given `point = {2, 1}`, we know that we can destructure it:

```
{x, y} = point
```

But we can take it to next level and make it conditional:

```
{x, 1} = point        # x becomes 2, only if y is 1
```

This is called pattern matching. We can use it for making assertions about the shapes and values of data. If we provide multiple patterns, we can use pattern matching for control flow. Two most common ways are - `case` expression:

```
case point do
  {x, 1} -> "point with y == 1"
  {x, y} -> "any other point"
  _ -> "that's not what I call a point"       # catch-all pattern is optional
end
```

and function clauses:

```
defmodule MyEnum do
  def sum([], total) do                 # will be invoked only when the first argument is [] - an empty list
    total
  end

  def sum([head | tail], total) do      # we can write "[head | tail] = list" if we need "list" as a whole
    sum(tail, total + head)
  end
end
```

If none of the patterns match, an error occurs:

```
{x, 2} = point        # ** (MatchError) no match of right hand side value: {2, 1}
```

The patterns in `case` expressions and function clauses can have additional conditions, called _guards_:

```
case thing do
  x when is_list(x) -> "that's a list"
  x when x > 5 -> "number larger than 5"
end
```

Note that not all functions can be used in guards, see [the list](https://hexdocs.pm/elixir/guards.html). All the available functions have the "Allowed in guard tests." note in their documentation, for example `h is_list`.

## The puzzle

- try writing everything from scratch
- use `File.read!` to read file contents
- pass `trim: true` to `String.split` to get rid of the blanks
- the `Regex` module might be useful for parsing, but you might as well take a closer look at `String.split`...
- use `String.to_integer` for conversion; check out docs for `Integer.parse` to see the difference
