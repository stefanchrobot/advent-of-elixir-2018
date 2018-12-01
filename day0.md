# Advent of Elixir 2018 - day 0

Let’s set up our local env:

`$ brew install elixir`

You’ve just installed the following tools:

- `elixir`: the Elixir compiler and runner
- `iex`: Elixir interactive shell
- `mix`: Elixir project manager and task runner

Let’s verify if things work with the obligatory “hello world”:

```
$ mkdir advent-of-elixir; cd advent-of-elixir`
$ echo 'IO.puts "Advent of Elixir 2018"' > hello_world.exs`
```

and let’s run it:

`$ elixir hello_world.exs`

Now let’s check out the `iex`:

```
$ iex
Erlang/OTP 21 [erts-10.0.7] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Interactive Elixir (1.6.6) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

You can use the shell to evaluate any expressions, for example:

```
iex> "1 + 1 is #{1+1}"
iex> c "hello_world.exs"  # compile and run the file
iex> h Enum               # documentation about the "Enum" module
iex> h Enum.map           # documentation about the "map" function from the "Enum" module
```

Press `Ctrl+C` _twice_ to quit `iex`.

:+1: if you got this far! Next time we’ll learn about Elixir basics.
If you want more now: https://elixir-lang.org/getting-started/introduction.html

## Bonus points

Elixir has an opinionated, generally adopted code formatter - let’s join the club; let’s tell it what we want to format:

`$ echo '[inputs: ["*.exs", "*.ex"]]' > .formatter.exs`

and now we can format all our code with:

`$ mix format`
