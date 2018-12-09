# Advent of Elixir 2018 - day 5

## The mix tool

Mix is _the_ Elixir project management tool and task runner. Out of the box we get the following tasks:
- creating a project
- compiling
- downloading dependencies
- running the tests
- formatting the code

and more. Run `mix help` for the comprehensive list or `mix help <task>` for help on specific task.

## Creating a project

Run `mix new <name>` to create a new Elixir project:

```
$ mix new advent
...
$ tree -a advent

advent/
├── config                    # compile-time config files
│   └── config.exs
├── lib                       # source code
│   └── advent.ex             # auto-generated "Advent" module
├── test                      # test code
│   ├── advent_test.exs       # sample test
│   └── test_helper.exs       # helpers for testing, starts the testing library
├── .formatter.exs            # formatter configuration
├── .gitignore                # Git ignore file suitable for Elixir projects
├── mix.exs                   # project definition (name, deps, etc.)
└── README.md                 # sample README
```

By convention, nested modules live in nested directories:

```
...
├── lib
│   ├── advent
│   │   ├── day_one.ex        # defmodule Advent.DayOne do ...
│   │   └── day_two.ex        # defmodule Advent.DayTwo do ...
│   └── advent.ex             # defmodule Advent do ...
...
```

## .ex vs .exs

When any mix task is invoked, all `.ex` files in the project are compiled, hence they are available for use. `.exs` files are considered scripts and are not automatically compiled.

## IEx and your app

If you run `iex` it doesn't know anything about your project. To run it in the scope of your app, use the following:

```
$ iex -S mix

iex> Advent.hello()
```

## Documentation

Elixir has a first-class support for documentation. The documentation is then available in IEx in the `h` helper. For example, see the auto-generated module `advent.ex` - the `@moduledoc` and `@doc` attributes.

You can easily generate beautiful HTML pages using [ExDoc](https://hexdocs.pm/ex_doc/readme.html).

## Managing dependencies

Dependencies are defined in the `mix.exs` file and can be sourced from disk, Git repos or the official package repository - [Hex](hex.pm). For example, let's add an HTTP client - [tesla](https://hex.pm/packages/tesla):

```
  defp deps do
    [{:tesla, "~> 1.2"}]
  end
```

Let's fetch the deps:

```
$ mix deps.get
```

and now we can use it in our code or in IEx:

```
$ iex -S mix

iex> Tesla.get("http://httpbin.org/ip")
```

## alias vs import vs require vs use

There are four instructions for using other modules in the current one:

```
defmodule MyModule do
  <instruction> SomeModule

  # ...
end
```

- `alias`: gives another name to a module to avoid long names or name conflicts:
```
alias SomeModule.NestedModule         # use "NestedModule" instead of "SomeModule.NestedModule"
alias SomeModule.{A, B}               # uese "A" instead of "SomeModule.A" and "B" instead of "SomeModule.B"
alias FancyMap, as: Map               # use "Map" instead of "FancyMap"
```
- `import`: brings functions from a module into the current scope
```
import SomeModule                     # use "func()" instead of "SomeModule.func()"; use sparingly
import SomeModule, only: [func: 1]    # import only SomeModule.func/1
```
- `require`: explicitly opts-in to macros (metaprogramming capabilities) provided by `SomeModule`; note that `import`ing a module `require`s it
- `use`: allows `SomeModule` to inject code into the current module; usually the injected code does some `import`/`require`

## Testing

### Unit tests

Writing tests is pretty straightforward:

```
defmodule MyModuleTest do               # convention <module under test>Test
  use ExUnit.Case                       # let the ExUnit library inject some code: test, assert, etc.

  test "simplest one" do
    assert 1 + 1 == 2
  end
end
```

### Doctests

You can embed test cases into the documentation. That's especially useful for functions with no setup:

```
defmodule Sample do
  @doc """
  Prettyfies a name.

  ## Examples

      iex> Sample.pretty_name("  james   arthur  smith   ")
      "James Arthur Smith"
  """
  def pretty_name(string) do
    # ...
  end
end
```

The examples will be run as actual tests. But no magic involved, you need to opt-in for this:

```
defmodule SampleTest do
  use ExUnit.Case
  doctest Sample            # opt-in to doctests
end
```

## Metaprogramming

Let's try to break the auto-generated test:

```
test "greets the world" do
  assert Advent.hello() == :worlds        # :world -> :worlds
end
```

What's going to happen when we run the test? What's going to be the output of the test? Why?

What if I told you that `if` is not a keyword. Same goes for `unless`, `with` and `for`. And also `import`, `alias`, `def`, `defmodule` and more. Just like ExUnit's `test`, they're macros: you call it like a regular function, but it generates some code during _compilation_.

What can you do during macro evaluation? Basically, anything! Generate code from scratch, transform passed code, perform calculations. How about making HTTP requests? No problem:

```
defmodule SkyIsTheLimit do
  # "defmacro" defines a macro
  defmacro ip do
    {:ok, %{body: body}} = Tesla.get("http://httpbin.org/ip")
    IO.puts("your IP is #{String.slice(body, 15..-5)}")
  end
end

defmodule MyModule do
  import SkyIsTheLimit

  def hello do
    ip()
    :world
  end
end
```

### Macros return code

Macro should return a piece of code that's going to be injected into the call site. Since a macro can run normal Elixir code, how do we express the code to be injected? We need to put it into _quotes_. And then we need to be able to interpolate (_unquote_) it to inject values:

```
defmodule MyMacros do
  @doc """
  Defines a hello_world function with the specified return value.
  """
  defmacro define_hello(value) do
    "def hello_world(), do: #{value}"             # warning: not actual Elixir
  end
end
```

While this is how it conceptually works, concatenating strings is no fun, does not allow for syntax highlighting and it's not actually the way it's done. This is how you do it:

```
defmodule MyMacros do
  defmacro define_hello(value) do
    quote do
      def hello_world(), do: unquote(value)
    end
  end
end
```

And then use it:

```
defmodule Sample do
  import MyMacros

  define_hello("hi!")
end
```

## Code is data

The nicest thing about working with macros is that code is just data:

```
iex> quote do       # returns the representation of quoted code
...>   min(5, 7)
...> end
{:min, [context: Elixir, import: Kernel], [5, 7]}
```

As a programmer you get access to almost the same tools as the Elixir creators. But, as usual... with great power comes great responsibility. Prefer functions to macros, but reach out for them if you can reduce boilerplate and provide optimizations. Here's an example from the Phoenix framework (the equivalent of Rails, Django, Express) that has a DSL for defining the routing which compiles down to very efficient pattern matching:

```
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWeb do
  #   pipe_through :api
  # end
end
```

Here's a great [tutorial on macros](https://www.theerlangelist.com/article/macros_1).
