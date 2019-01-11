defmodule Hastega.Db do

  def write_function({key, value}, module) do
    :mnesia.dirty_write({
      :functions,
      key,
      module,
      value[:function_name],
      value[:is_public],
      value[:is_nif],
      value[:args],
      value[:do]})
  end

  def read_function(id) do
    :mnesia.dirty_read({:functions, id})
  end

  def all_functions() do
    :mnesia.dirty_all_keys(:functions)
  end

end