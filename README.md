# Advent of Elixir 2018

Puzzles and my solutions for the [Advent of Code 2018](https://adventofcode.com/2018) in [Elixir](https://elixir-lang.org/).

To spread the love of Elixir, I gather a group of people in [AirHelp](https://www.airhelp.com/en/) that wanted to tackle the Advent of Code 2018 in a functional language. The idea was to introduce the functional programming concepts one at a time to people with previous programming knowledge in Ruby, Python and JavaScript. It was more about learning functional programming, than solving the puzzles so we went 1 puzzle per day (or sometimes even slower). The [intro-to-elixir](intro-to-elixir) directory contains the reading materials for each day. In summary those include:

- setting up Elixir on Mac and the introduction to the Elixir command-line tools,
- basic types, data structures, immutability, modules and functions and the enumerables,
- recursion,
- lists, destructuring and pipes,
- maps, capture operator and pattern matching,
- control-flow expresssions, streams and structs,
- managing a project with mix and various mix tasks, documentation, tests and metaprogramming,
- introduction to concurrency.

As a consequence, the solutions for days 1 to 3 use some vary basic Elixir. After that, I used Elixir features as I saw fit. Since day 7, I've started using doctests - I took this from watching José Valim's Twitch stream. In my solutions, I use the doctests heavily, sometimes to the point of abusing them - in many cases the examples were copied straight from the puzzles which made the doctests overly long.

The puzzles that were the most fun:

- Day 10: "image recognition",
- Day 12 and 18: 1D/2D game of life,
- Day 13: simulating moving carts,
- Day 15: simulating a [roguelike](https://en.wikipedia.org/wiki/Roguelike) game,
- Day 16 and 19: writing a VM, implementing new instructions, writing a debugger,
- Day 17: writing a "physics engine".
