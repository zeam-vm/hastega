defmodule Hastega.Parser do

  @moduledoc """
  Documentation for Hastega.Parser.
  """

  @doc """
  		## Examples
  		iex> {:__block__, [], []} |> Hastega.Parser.parse()
  		[]

  		iex> {:def, [line: 8], [{:func, [line: 8], [{:a, [line: 8], nil}]}, [do: {:a, [line: 8], nil}]]} |> Hastega.Parser.parse()
  		[[function_name: :func, is_public: true, args: [:a]]]
  """
  def parse({:__block__, [], []}), do: []
  def parse({:def, _env, body}), do: [[function_name: parse_function_name(body), is_public: true, args: parse_args(body)]]

  @doc """
  		## Examples
  		iex> {:def, [line: 5], [{:func, [line: 5], [{:a, [line: 5], nil}]}, [do: {:a, [line: 5], nil}]]} |> Hastega.Parser.parse_def()
  		[function_name: :func, is_public: true]

  		iex> {:defp, [line: 5], [{:func, [line: 5], [{:a, [line: 5], nil}]}, [do: {:a, [line: 5], nil}]]} |> Hastega.Parser.parse_def()
  		[function_name: :func, is_public: false]

  """
  def parse_def(element) do
  	case element do
  		{:def, _env, body} -> [function_name: parse_function_name(body), is_public: true]
  		{:defp, _env, body} -> [function_name: parse_function_name(body), is_public: false]
  	end
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