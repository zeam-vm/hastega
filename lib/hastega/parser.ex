defmodule Hastega.Parser do

  @moduledoc """
  Documentation for Hastega.Parser.
  """

  @doc """
  		## Examples
  		iex> quote do end |> Hastega.Parser.parse()
  		[]

  		iex> (quote do: def func(a), do: a) |> Hastega.Parser.parse()
  		[[function_name: :func, is_public: true, args: [:a]]]

  		iex> (quote do
  		...>   def func(a), do: funcp(a)
  		...>   defp funcp(a), do: a
  		...> end) |> Hastega.Parser.parse()
  		[[function_name: :func, is_public: true, args: [:a]], [function_name: :funcp, is_public: false, args: [:a]]]
  """
  def parse({:__block__, _env, []}), do: []

  def parse({:def, _env, body}) do
  	[[
  		function_name: parse_function_name(body),
  		is_public: true,
  		args: parse_args(body)
  	]]
  end

  def parse({:defp, _env, body}) do
  	[[
  		function_name: parse_function_name(body),
  		is_public: false,
  		args: parse_args(body)
  	]]
  end

  def parse({:__block__, _env, body_list}) do
  	body_list
  	|> Enum.map(& &1 |> parse() |> hd())
  end

  defp parse_function_name(body), do: body |> hd |> elem(0)

	defp parse_args(body) do
		body
		|> hd
		|> elem(2)
		|> convert_args()
	end

  defp convert_args(arg_list), do: arg_list |> Enum.map(& elem(&1, 0))
end