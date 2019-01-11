defmodule Hastega do
  require Hastega.Imports
  import Hastega.Imports
  import Hastega.Util
  import Hastega.Parser
  require Hastega.Db
  import Hastega.Db

  @moduledoc """
  Documentation for Hastega.
  """

  defmacro defhastega clause do

    functions = clause
    |> Keyword.get(:do, nil)
    |> parse()

    Stream.iterate(1, &(&1 + 1))
    |> Enum.zip(functions)
    |> Enum.map(& write_function(&1, "#{__CALLER__.module}"))

    quote do
      unquote(clause)
    end
  end

  defmacro hastegastub do
    all_functions()
    |> Enum.map(& hd(read_function(&1)))
    |> Enum.map(& Hastega.Generator.generate_nif(&1))
    |> IO.inspect

    quote do end
  end
end
