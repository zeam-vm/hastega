defmodule Hastega do
  require Hastega.Imports
  import Hastega.Imports
  import Hastega.Util
  import Hastega.Parser
  import Hastega.Db

  @moduledoc """
  Documentation for Hastega.
  """

  @on_load :on_load

  def on_load do
    case :mnesia.start do
      :ok -> case :mnesia.create_table( :functions, [ attributes: [ :id, :module_name, :function_name, :is_public, :is_nif, :args, :do ] ] ) do
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
