defmodule Hastega.Parser do

  @moduledoc """
  Documentation for Hastega.Parser.
  """

  @doc """
  		## Examples
  		iex> quote do end |> Hastega.Parser.parse()
  		[]

  		iex> (quote do: def func(a), do: a) |> Hastega.Parser.parse()
  		[[function_name: :func, is_public: true, args: [:a], do: [{:a, [], Hastega.ParserTest}], is_nif: false ]]

  		iex> (quote do
  		...>   def func(a), do: funcp(a)
  		...>   defp funcp(a), do: a
  		...> end) |> Hastega.Parser.parse()
  		[[function_name: :func, is_public: true, args: [:a], do: [{:funcp, [], [{:a, [], Hastega.ParserTest}]}], is_nif: false ], [function_name: :funcp, is_public: false, args: [:a], do: [{:a, [], Hastega.ParserTest}], is_nif: false ]]

      iex> (quote do
      ...>    def func(list) do
      ...>      list
      ...>      |> Enum.map(& &1)
      ...>    end
      ...> end) |> Hastega.Parser.parse()
      [[function_name: :func, is_public: true, args: [:list], do: [{:|>, [context: Hastega.ParserTest, import: Kernel], [{:list, [], Hastega.ParserTest}, {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [], [{:&, [], [{:&, [], [1]}]}]}]}], is_nif: false ]]
  """
  def parse({:__block__, _env, []}), do: []

  def parse({:def, _env, body}) do
    parse_nifs(body)

  	[[
  		function_name: SumMag.parse_function_name(body),
  		is_public: true,
  		args: SumMag.parse_args(body),
      do: SumMag.parse_do(body),
      is_nif: false
  	]]
  end

  def parse({:defp, _env, body}) do
    parse_nifs(body)

  	[[
  		function_name: SumMag.parse_function_name(body),
  		is_public: false,
  		args: SumMag.parse_args(body),
      do: SumMag.parse_do(body),
      is_nif: false
  	]]
  end

  def parse({:__block__, _env, body_list}) do
  	body_list
  	|> Enum.map(& &1
  		|> parse()
  		|> hd() )
  	|> Enum.reject(& &1 == :ignore_parse)
  end

  def parse({:hastegastub, _env, nil}) do
  	[:ignore_parse]
  end

  defp parse_nifs(body) do
    body
    |> tl
    |> hd
    |> hd
    |> parse_nifs_do_block([
      function_name: (SumMag.parse_function_name(body)
        |> SumMag.concat_name_nif() ),
      is_public: true,
      args: SumMag.parse_args(body),
      is_nif: true])
  end

  defp parse_nifs_do_block({:do, do_body}, kl), do: parse_nifs_do_body(do_body, kl)

  defp parse_nifs_do_body({:__block__, _env, []}, _kl), do: []

  defp parse_nifs_do_body({:__block__, _env, body_list}, kl) do
    body_list
    |> Enum.map(& &1
      |> parse_nifs_do_body(kl)
      |> hd() )
  end

  defp parse_nifs_do_body({:|>, _env, pipes}, kl) do
    IO.inspect pipes
  end

  defp parse_nifs_do_body(value, _kl) do
    [value]
  end
end