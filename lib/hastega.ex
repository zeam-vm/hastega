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
      :ok -> case :mnesia.create_table( :functions, [ attributes: [ :id, :module_name, :function_name, :is_public, :args, :do ] ] ) do
        {:atomic, :ok} -> :ok
        _ -> :err
      end
      _ -> :err
    end
  end

  def write_function({key, value}, module) do
    :mnesia.dirty_write({
      :functions,
      key,
      module,
      value[:function_name],
      value[:is_public],
      value[:args],
      value[:do]})
  end

  def read_function(id) do
    :mnesia.dirty_read({:functions, id})
  end

  def all_functions() do
    :mnesia.dirty_all_keys(:functions)
  end

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
    functions = all_functions() |> Enum.map(& hd(read_function(&1)))

    functions
    |> Enum.map(& Hastega.Generator.generate_nif(&1))

    quote do end
  end
end
