defmodule NifGenerator do
  def generate_enum_chunk_every(num) do
    quote do: VecSample.chunk_every(4)
  end

  def generate_enum_map_for_binomial_expr(operator, left, right) do
    quote do: VecSample.enum_map_mult_2
  end
end