defmodule Day07 do
  def example() do
    """
    Step C must be finished before step A can begin.
    Step C must be finished before step F can begin.
    Step A must be finished before step B can begin.
    Step A must be finished before step D can begin.
    Step B must be finished before step E can begin.
    Step D must be finished before step E can begin.
    Step F must be finished before step E can begin.
    """
    |> String.split("\n", trim: true)
    |> parse_deps()
  end

  def input() do
    "day07_input.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> parse_deps()
  end

  @doc """
  Parses the dependencies between steps.

      iex> Day07.parse_deps([
      ...>   "Step C must be finished before step A can begin.",
      ...>   "Step C must be finished before step F can begin.",
      ...>   "Step A must be finished before step B can begin.",
      ...>   "Step A must be finished before step D can begin.",
      ...>   "Step B must be finished before step E can begin.",
      ...>   "Step D must be finished before step E can begin.",
      ...>   "Step F must be finished before step E can begin."
      ...> ])
      [{"C", "A"}, {"C", "F"}, {"A", "B"}, {"A", "D"}, {"B", "E"}, {"D", "E"}, {"F", "E"}]
  """
  def parse_deps(deps) do
    Enum.map(deps, fn dep ->
      <<"Step ", x::utf8, " must be finished before step ", y::utf8, " can begin.">> = dep
      {<<x>>, <<y>>}
    end)
  end

  @doc """
  Extracts the steps from the dependencies.

      iex> set = Day07.extract_steps([{"C", "A"}, {"C", "F"}, {"A", "B"}, {"A", "D"}, {"B", "E"}, {"D", "E"}, {"F", "E"}])
      iex> set |> Enum.sort()
      ["A", "B", "C", "D", "E", "F"]

      iex> Day07.extract_steps([{"A", "B"}]) |> Enum.sort()
      ["A", "B"]
  """
  def extract_steps(deps) do
    deps
    |> Enum.flat_map(fn {x, y} -> [x, y] end)
    |> Enum.uniq()
  end

  @doc """
  Finds steps that are not dependant on others.

      iex> Day07.steps_without_deps(["A", "B", "C"], [{"C", "A"}, {"C", "B"}, {"A", "B"}]) |> Enum.sort()
      ["C"]

  """
  def steps_without_deps(steps, deps) do
    Enum.reduce(deps, MapSet.new(steps), fn {_x, y}, steps_without_deps ->
      MapSet.delete(steps_without_deps, y)
    end)
  end

  @doc """
  Finds the correct order of the step execution.

      iex> Day07.find_order([{"A", "B"}, {"B", "C"}])
      ["A", "B", "C"]

      iex> Day07.find_order([{"C", "A"}, {"C", "F"}, {"A", "B"}, {"A", "D"}, {"B", "E"}, {"D", "E"}, {"F", "E"}])
      ["C", "A", "B", "D", "F", "E"]
  """
  def find_order(deps) do
    deps
    |> extract_steps()
    |> find_order(deps, [])
  end

  defp find_order([], [], order) do
    Enum.reverse(order)
  end

  defp find_order(steps, deps, order) do
    next_step =
      steps
      |> steps_without_deps(deps)
      |> Enum.min()

    remaining_steps = steps -- [next_step]
    remaining_deps = Enum.reject(deps, fn {x, _y} -> x == next_step end)

    find_order(remaining_steps, remaining_deps, [next_step | order])
  end

  def part1() do
    input()
    |> find_order()
    |> Enum.join()
  end

  # iex> Day07.minimum_execution_time([{"A", "B"}, {"B", "C"}], 1, 0)
  # 6

  @doc """
  Calculates minimum execution time.

      iex> deps = [{"A", "B"}]
      iex> Day07.minimum_execution_time(deps)
      3

      iex> deps = [{"C", "A"}, {"C", "F"}, {"A", "B"}, {"A", "D"}, {"B", "E"}, {"D", "E"}, {"F", "E"}]
      iex> Day07.minimum_execution_time(deps, worker_pool: 2, base_time: 0)
      15
  """
  def minimum_execution_time(deps, opts \\ [worker_pool: 2, base_time: 0]) do
    deps
    |> extract_steps()
    |> Enum.to_list()
    |> minimum_execution_time([], deps, [], 0, opts)
  end

  defp minimum_execution_time([], [], [], [], elapsed_time, _opts) do
    elapsed_time
  end

  defp minimum_execution_time(
         waiting_steps,
         in_progress_steps,
         deps,
         busy_workers,
         elapsed_time,
         opts
       ) do
    idle_workers_count = opts[:worker_pool] - length(busy_workers)

    available_steps =
      waiting_steps
      |> steps_without_deps(deps)
      |> Enum.sort()

    if idle_workers_count > 0 and available_steps != [] do
      steps_to_start = Enum.take(available_steps, idle_workers_count)
      remaining_waiting_steps = waiting_steps -- steps_to_start
      started_workers = Enum.map(steps_to_start, &{&1, required_time(&1, opts[:base_time])})

      minimum_execution_time(
        remaining_waiting_steps,
        in_progress_steps,
        deps,
        busy_workers ++ started_workers,
        elapsed_time,
        opts
      )
    else
      {progressed_time, completed_workers, incomplete_workers} =
        progress_time_till_first_completion(busy_workers)

      # for _x <- 1..progressed_time do
      #   busy_workers
      #   |> Enum.map(fn {step, _} -> step end)
      #   |> Enum.join(" ")
      #   |> IO.puts()
      # end

      completed_steps = Enum.map(completed_workers, fn {step, 0} -> step end)
      remaining_in_progress_steps = in_progress_steps -- completed_steps
      remaining_deps = Enum.reject(deps, fn {x, _y} -> x in completed_steps end)

      minimum_execution_time(
        waiting_steps,
        remaining_in_progress_steps,
        remaining_deps,
        incomplete_workers,
        elapsed_time + progressed_time,
        opts
      )
    end
  end

  @doc """
  Progresses by the minimum amount of time required for at least one worker to finish.
  Returns a tuple {elapsed_time, completed_workers, incomplete_workers}.
  """
  def progress_time_till_first_completion(workers) do
    {_step, min_time_remaining} =
      Enum.min_by(workers, fn {_step, remaining_time} -> remaining_time end)

    {completed, incomplete} =
      workers
      |> Enum.map(fn {step, remaining_time} -> {step, remaining_time - min_time_remaining} end)
      |> Enum.split_with(fn {_step, remaining_time} -> remaining_time == 0 end)

    {min_time_remaining, completed, incomplete}
  end

  def part2() do
    # example()
    # |> minimum_execution_time(worker_pool: 2, base_time: 0)

    input()
    |> minimum_execution_time(worker_pool: 5, base_time: 60)
  end

  @doc """
  Returns the time cost of performing the specific step.

      iex> Day07.required_time("A")
      1

      iex> Day07.required_time("E", 0)
      5
  """
  def required_time(<<char::utf8>>, base_requirement \\ 0) do
    base_requirement + (char - ?A) + 1
  end
end
