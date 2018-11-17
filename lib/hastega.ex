defmodule Hastega do
  require Hastega.Imports
  import Hastega.Imports
  import Hastega.Util
  import Hastega.Parser

  @moduledoc """
  Documentation for Hastega.
  """

  @on_load :on_load

  def on_load do
    case :mnesia.start do
      :ok -> case :mnesia.create_table( :functions, [ attributes: [ :id, :module_name, :function_name, :is_public, :args ] ] ) do
        {:atomic, :ok} -> :ok
        _ -> :err
      end
      _ -> :err
    end
  end

  defmacro defhastega clause do

    functions = clause
    |> Keyword.get(:do, nil)
    |> parse()

    Stream.iterate(1, &(&1 + 1))
    |> Enum.zip(functions)
    |> Enum.map(& :mnesia.dirty_write(
      {:functions,
        elem(&1, 0),
        "#{__CALLER__.module}",
        elem(&1, 1)[:function_name],
        elem(&1, 1)[:is_public],
        elem(&1, 1)[:args]}))

    quote do
      unquote(clause)
    end
  end

  defmacro hastegastub do
    :mnesia.dirty_all_keys(:functions)
    |> Enum.map(& :mnesia.dirty_read({:functions, &1}))
    |> IO.inspect

    quote do end
  end
end
