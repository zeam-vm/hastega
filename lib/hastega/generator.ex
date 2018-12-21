defmodule Hastega.Generator do

  @moduledoc """
  Documentation for Hastega.Generator.
  """

  def generate_nif({:functions, id, module_name, function_name, is_public, args, body}) do
  	
  	{:functions, id, module_name, function_name, is_public, args, body}
  end
end