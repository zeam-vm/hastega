defmodule Hastega.Parser do

  @moduledoc """
  Documentation for Hastega.Parser.
  """

  @doc """
  		## Examples
  		iex> quote do end |> Hastega.Parser.parse(%{target: :hastega})
  		[]

  		iex> (quote do: def func(a), do: a) |> Hastega.Parser.parse(%{target: :hastega})
  		[[function_name: :func, is_public: true, args: [:a], do: [{:a, [], Hastega.ParserTest}], is_nif: false ]]

  		iex> (quote do
  		...>   def func(a), do: funcp(a)
  		...>   defp funcp(a), do: a
  		...> end) |> Hastega.Parser.parse(%{target: :hastega})
  		[[function_name: :func, is_public: true, args: [:a], do: [{:funcp, [], [{:a, [], Hastega.ParserTest}]}], is_nif: false ], [function_name: :funcp, is_public: false, args: [:a], do: [{:a, [], Hastega.ParserTest}], is_nif: false ]]

      iex> (quote do
      ...>    def func(list) do
      ...>      list
      ...>      |> Enum.map(& &1)
      ...>    end
      ...> end) |> Hastega.Parser.parse(%{target: :hastega})
      [[function_name: :func, is_public: true, args: [:list], do: [{:|>, [context: Hastega.ParserTest, import: Kernel], [{:list, [], Hastega.ParserTest}, {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [], [{:&, [], [{:&, [], [1]}]}]}]}], is_nif: false ]]
  """
  def parse({:hastegastub, _e, nil}, _env) do
    [:ignore_parse]
  end

  def parse({:def, e, body}, env) do
    parse_nifs(body, env)
    SumMag.parse({:def, e, body}, env)
  end

  def parse({:defp, e, body}, env) do
    parse_nifs(body, env)
    SumMag.parse({:defp, e, body}, env)
  end

  def parse({:__block__, _e, []}, _env), do: []

  def parse({:__block__, _e, body_list}, env) do
  	body_list
  	|> Enum.map(& &1
  		|> parse(env)
  		|> hd() )
  	|> Enum.reject(& &1 == :ignore_parse)
  end


  defp parse_nifs(body, env) do
    body
    |> tl
    |> hd
    |> hd
    |> parse_nifs_do_block(
      [function_name: (SumMag.parse_function_name(body, env)
        |> SumMag.concat_name_nif(env) ),
        is_public: true,
        args: SumMag.parse_args(body, env),
        is_nif: true],
      env)
  end

  defp parse_nifs_do_block({:do, do_body}, kl, env), do: parse_nifs_do_body(do_body, kl, env)

  defp parse_nifs_do_body({:__block__, _e, []}, _kl, _env), do: []

  defp parse_nifs_do_body({:__block__, _e, body_list}, kl, env) do
    body_list
    |> Enum.map(& &1
      |> parse_nifs_do_body(kl, env)
      |> hd() )
  end

  defp parse_nifs_do_body({:|>, _e, pipes}, _kl, _env) do
    IO.inspect pipes
  end

  defp parse_nifs_do_body(value, _kl, _env) do
    [value]
  end
end