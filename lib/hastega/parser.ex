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
    env = Map.put_new(env, :num, 0)
    env = Map.put(env, :num, increment_nif(env))
    parse_nifs(body, env)
    SumMag.parse({:def, e, body}, env)
  end

  def parse({:defp, e, body}, env) do
    env = Map.put_new(env, :num, 0)
    env = Map.put(env, :num, increment_nif(env))
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

  # match `p |> Enum.map(body)`
  defp parse_nifs_do_body({:|>, _e1, [p, {{:., _e2, [{:__aliases__, _e3, [:Enum]}, :map]}, _e4, body}]}, kl, env) do
    env = Map.put(env, :nif, func_with_num(kl, env))
    parse_enum_map(p, body, kl, env)
  end

  defp parse_nifs_do_body(value, _kl, _env) do
    [value]
  end

  def parse_enum_map({:|>, _e1, [p, {{:., _e2, [{:__aliases__, _e3, [:Enum]}, :map]}, _e4, body}]}, calling, kl, env) do
    {p_body, kl, env} = parse_enum_map(p, body, kl, env)
    IO.puts "p_body:"
    IO.inspect p_body
    IO.puts "body:"
    IO.inspect body
    IO.puts "calling:"
    IO.inspect calling
    IO.puts "kl:"
    IO.inspect kl
    IO.puts "env:"
    IO.inspect env
    {body, kl, env}
  end

  def parse_enum_map(previous, calling, kl, env) do
    IO.puts "previous:"
    IO.inspect previous
    IO.puts "calling:"
    IO.inspect calling
    IO.puts "kl:"
    IO.inspect kl
    IO.puts "env:"
    IO.inspect env
    {calling, kl, env}
  end

  def func_with_num(kl, env) do
    Keyword.put(kl, :target_func, (kl[:function_name] |> concat_name_num(env)))
  end

  def get_func_info(%{target_func: func_info}), do: func_info

  def merge_func_info(env, keyword) do
    Map.put(env, :target_func, Keyword.merge(get_func_info(env), keyword))
  end

  @doc """
    ## Examples

    iex> Hastega.Parser.increment_nif(%{num: 0})
    1

    iex> Hastega.Parser.increment_nif(%{num: 1})
    2
  """
  def increment_nif(%{num: num}) do
    num + 1
  end

  @doc """
    ## Examples

    iex> :func |> Hastega.Parser.concat_name_num(%{num: 1})
    :func_1

    iex> :fl |> Hastega.Parser.concat_name_num(%{num: 2})
    :fl_2
  """
  def concat_name_num(name, %{num: num}) do
    name |> Atom.to_string |> Kernel.<>("_#{num}") |> String.to_atom
  end
end