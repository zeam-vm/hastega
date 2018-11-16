defmodule Hastega do
  import Hastega.Util
  import Hastega.Parser

  @moduledoc """
  Documentation for Hastega.
  """

  defmacro defhastega clause do

    do_clauses = clause
    |> Keyword.get(:do, nil)
    |> wrap_do_clauses

    :mnesia.dirty_write({:functions, 1, "#{__CALLER__.module}"})

    quote do
      unquote(clause)
    end
  end

  defmacro hastegastub do
  end
end
