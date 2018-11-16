defmodule Hastega do
  @moduledoc """
  Documentation for Hastega.
  """

  defmacro defhastega do_clause do
    quote do: unquote(do_clause)
  end

  defmacro hastegastub do
  end
end
