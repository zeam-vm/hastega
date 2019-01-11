defmodule Hastega.Db do

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