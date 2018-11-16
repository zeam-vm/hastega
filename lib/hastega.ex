defmodule Hastega do
  import Hastega.Util
  import Hastega.Parser

  @moduledoc """
  Documentation for Hastega.
  """

  defmacro defhastega clause do

    functions = clause
    |> Keyword.get(:do, nil)
    |> parse()

    Stream.iterate(1, &(&1 + 1))
    |> Enum.zip(functions)
    |> IO.inspect
    |> Enum.map(& :mnesia.dirty_write({:functions, elem(&1, 0), "#{__CALLER__.module}", elem(&1, 1)[:function_name], elem(&1, 1)[:is_public]}))

    quote do
      unquote(clause)
    end
  end

  defmacro hastegastub do
  end
end
