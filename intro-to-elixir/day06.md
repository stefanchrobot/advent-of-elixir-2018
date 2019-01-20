# Advent of Elixir 2018 - day 6

## Concurrency vs parallelism

```
 concurrency                         parallelism
(single core)                   (multicore/distributed)

    A                                   A   B
    A                                   A   B
    A                                   A   B
        B                               A   B
        B                               A   B
    A
    A
        B
        B
        B
```

Elixir (Erlang) makes it easy to write concurrent programs. Due to it's functional nature, it's trivial for the VM to run such programs with parallelism.

## Erlang process - the unit of concurrency

An Erlang process is very much like an OS process:
- has a unique pid,
- it's isolated: shares no resources with other processes (own stack and heap),
- runs concurrently,
- it's preemptive: the scheduler takes care of giving everybody their fair share of the CPU.

The major differance is that an Erlang process is cheap: the memory footprint is minimal, creating and killing a process is a lightweight operation.

## Creating a process

To create a process, call the `spawn()` function and pass a function to be run by the process. You'll get back the process id (pid) in return:

```
pid = spawn(fn -> IO.puts("hello!") end)
```

To see that the process runs concurrently, we can make it sleep and print a message after some time:

```
spawn(fn ->
  Process.sleep(3000)     # for educational purposes only; avoid "sleep"
  IO.puts("hello!")
end)
```

The process exits once the function has finished executing.

## Long running processes

To create a long-running process, we can pass a recursive function:

```
defmodule Printer do
  def loop() do
    IO.puts("hi, there!")
    Process.sleep(1000)
    loop()                    # tail-recursive, it can go on forever
  end
end

spawn(&Printer.loop/0)
```

## Stateful processes

We can make the processes stateful by using an accumulator:

```
defmodule Counter do
  def loop(state) do
    IO.puts(state)
    Process.sleep(1000)
    loop(state + 1)
  end
end

spawn(fn -> Counter.loop(0) end)
```

## Process communication

The only way to communicate between processes is by sending a message. You do that with the `send()` function. To receive a message, use the `receive` expression. Note that you can use pattern-matching in `receive`. You can always get the pid of the current process by calling `self()`:

```
defmodule PingServer do
  def loop() do
    receive do                      # synchronously wait for a message
      {:ping, sender_pid} ->        # process messages that match the pattern
        send(sender_pid, :pong)     # let's just reply with ":pong"
    end
    loop()
  end
end
```

Couple of important notices:
- from the inside, the process is synchronous: it processes one message at a time,
- receiving a messages is a _blocking_ operation: the process will wait until a matching message is available,
- there is no pre-defined protocol for communication: it's up to you to define the message format; if you want to reply to the caller, you need to provide it's pid somehow.

We can test-drive the `PingServer` from IEx. Note that IEx is a process too:

```
iex> iex_pid = self()
iex> server_pid = spawn(&PingServer.loop/0)
iex> send(server_pid, {:ping, iex_pid})
iex> receive do
...>   msg -> IO.puts("got #{msg}")
...> end
```

## Client API

It's a common pattern to wrap the process creation and the details of the communication protocol with an easy to use API:

```
defmodule PingServer do
  def start() do                    # start the process, useful if we need to init some state
    spawn(&loop/0)
  end

  def ping(server_pid) do           # encapsulates the protocol for :ping
    caller_pid = self()
    send(server_pid, {:ping, caller_pid})
    receive do
      msg -> msg
    end
  end

  defp loop() do                    # no changes, except for defp
    receive do
      {:ping, sender_pid} ->
        send(sender_pid, :pong)
    end
    loop()
  end
end
```

This makes the usage much simpler:

```
iex> server_pid = PingServer.start()
iex> PingServer.ping(server_pid)
```

## Abstractions

Spawning processes is quite low-level. Most of the time you'll be using one of the battle-proven abstractions provided by the Erlang standard library (OTP) or bundled with Elixir. One of those abstractions is a `Task`: a simple API for running arbitrary computations. Here's how you use it:

```
iex> task = Task.async(fn -> 41 + 1 end)
iex> # do something else in the meantime
iex> result = Task.await(task)
```

Given what we know, we can implement a simplified version of it:

```
defmodule Task do
  def async(func) do
    caller_pid = self()
    # the returned "task" is the pid of the spawned process
    spawn(fn ->
      task_pid = self()
      result = func.()
      send(caller_pid, {:task_result, task_pid, result})
    end)
  end

  def await(task) do
    receive do
      # the task_pid has to match
      {:task_result, task_pid, result} when task_pid == task -> result# the task_ref has to match
    end
  end
end
```

We can use `Task`s to make our puzzle solutions concurrent:

```
list
|> Enum.map(fn input -> Task.async(fn -> some_code(input) end) end)
|> Enum.map(fn task -> Task.await(task) end)
```

The pattern is so common that it's available as a one-liner:

```
list
|> Task.async_stream(fn x -> some_code(x) end)
```

## Elixir as a functional language

On a basic level, Elixir is a functional language. But then `IO.puts("test")` always returns `:ok`, regardless of the input argument. That's not really functional (we know that the function has side effects and is not _pure_).

Elixir and Erlang were created for building concurrent (in fact, distributed), scalable and fault-tolerant systems. A key ingredient in achieving that is functional programming. But if you want to go beyond building a calculator, you need to somehow introduce state and side-effects. The Erlang's answer to that are processes. In my opinion, this is the most practical and approachable answer (the other ones are mixing FP and OOP or using monads).

You can think of a process as a concurrent execution of a pure function that on each message transforms the current state into the next state:

```
             +--------+
  state A -->|        |
             |   fn   |--> state B
message X -->|        |
             +--------+
```

There's a tendency to use processes to model objects from OOP, but that's an anti-pattern. Reach out for processes only when you need them: to keep some state in memory for a longer period of time; to leverage concurrency; or to isolate errors. Otherwise model your problem with pure functions and data transformations.

## Conclusion

We learned how to think and solve problems in terms of functional programming. We also learned the basics of concurrency. I hope that this was fun and informative!

As a follow up, I strongly suggest ["Elixir in Action, Second Edition"](https://www.manning.com/books/elixir-in-action-second-edition): it's a great read, one of the best books I've read. It has a great coverage of cuncurrency and OTP.
