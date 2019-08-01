defmodule SumMag do
  alias SumMag.Opt

  @moduledoc """
  SumMag: a meta-programming library for Hastega and Cockatorice.
  """

  @doc """
      ## Examples
      iex> quote do end |> SumMag.parse(%{target: :hastega})
      []

      iex> (quote do: def func(a), do: a) |> SumMag.parse(%{target: :hastega})
      [[function_name: :func, is_public: true, args: [:a], do: [{:a, [], SumMagTest}], is_nif: false ]]

      iex> (quote do
      ...>    def func(list) do
      ...>      list
      ...>      |> Enum.map(& &1)
      ...>    end
      ...> end) |> SumMag.parse(%{target: :hastega})
      [[function_name: :func, is_public: true, args: [:list], do: [{:|>, [context: SumMagTest, import: Kernel], [{:list, [], SumMagTest}, {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [], [{:&, [], [{:&, [], [1]}]}]}]}], is_nif: false ]]
  """
  def parse({:__block__, _e, []}, _env), do: []

  def parse({:def, _e, body}, env) do
    [[
      function_name: parse_function_name(body, env),
      is_public: true,
      args: parse_args(body, env),
      do: parse_do(body, env),
      is_nif: false
    ]]
  end

  def parse({:defp, _e, body}, env) do
    [[
      function_name: parse_function_name(body, env),
      is_public: false,
      args: parse_args(body, env),
      do: parse_do(body, env),
      is_nif: false
    ]]
  end

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_function_name(%{})
    :null

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_function_name(%{})
    :func

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_function_name(%{})
    :add
  """
  def parse_function_name(body, _env), do: body |> hd |> elem(0)

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_args(%{})
    []

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_args(%{})
    [:a]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_args(%{})
    [:a, :b]
  """
  def parse_args(body, env) do
    body
    |> hd
    |> elem(2)
    |> convert_args(env)
  end

  @doc """
    ## Examples

    iex> [] |> SumMag.convert_args(%{})
    []

    iex> [{:a, [], Elixir}] |> SumMag.convert_args(%{})
    [:a]

    iex> [{:a, [], Elixir}, {:b, [], Elixir}] |> SumMag.convert_args(%{})
    [:a, :b]
  """
  def convert_args(arg_list, _env), do: arg_list |> Enum.map(& elem(&1, 0))

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_do(%{})
    [{:nil, [], Elixir}]

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_do(%{})
    [{:a, [], Elixir}]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_do(%{})
    [{:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]
  """
  def parse_do(body, env) do
    body
    |> tl
    |> hd
    |> hd
    |> parse_do_block(env)
  end

  defp parse_do_block({:do, do_body}, env), do: parse_do_body(do_body, env)

  defp parse_do_body({:__block__, _e, []}, _env), do: []

  defp parse_do_body({:__block__, _e, body_list}, env) do
    body_list
    |> Enum.map(& &1
      |> parse_do_body(env)
      |> hd() )
  end

  defp parse_do_body(value, _env), do: [value]

  @doc """
    ## Examples

    iex> SumMag.increment_nif(%{num: 0})
    1

    iex> SumMag.increment_nif(%{num: 1})
    2
  """
  def increment_nif(%{num: num}) do
    num + 1
  end

  @doc """
    ## Examples

    iex> :func |> SumMag.concat_name_num(%{num: 1})
    :func_1

    iex> :fl |> SumMag.concat_name_num(%{num: 2})
    :fl_2
  """
  def concat_name_num(name, %{num: num}) do
    name |> Atom.to_string |> Kernel.<>("_#{num}") |> String.to_atom
  end

  @doc """
    ## Examples

    iex> :func |> SumMag.concat_name_nif(%{})
    :func_nif
  """
  def concat_name_nif(name, _env) do
    name |> Atom.to_string |> Kernel.<>("_nif") |> String.to_atom
  end

  @doc """
    ## Examples

    iex> :hastega |> SumMag.concat_name_stub(%{})
    :hastegastub
  """
  def concat_name_stub(name, _env) do
    name |> Atom.to_string |> Kernel.<>("stub") |> String.to_atom
  end

  @doc """
    ## Examples

    iex> SumMag.func_with_num([function_name: :func], %{num: 1})
    [function_name: :func_1]
  """
  def func_with_num(kl, env) do
    Keyword.put(kl, :function_name, (kl[:function_name] |> SumMag.concat_name_num(env)))
  end

  @doc """
    ## Examples

    iex> SumMag.get_func_info(%{nif: [function_name: :func]})
    [function_name: :func]
  """
  def get_func_info(%{nif: func_info}), do: func_info

  @doc """
    ## Examples

    iex> SumMag.merge_func_info(%{nif: [function_name: :func]}, [is_public: true])
    %{nif: [function_name: :func, is_public: true]}
  """
  def merge_func_info(env, keyword) do
    Map.put(env, :nif, Keyword.merge(get_func_info(env), keyword))
  end

  @doc """
  "defmacro do" take the following code.
  
  If you define a function:
  
  ```
  [ 
    do: {def, _line, [
      { :name, _line, arg },
      [
        do: main_process
      ]}
  ]
  ```      

  If you define functions:
  ```
  [ 
    do: {:__block__, [], [
      {def, _line, [{ :name, _line, arg },do: main_process
      ]}
  ]
  ```

        iex> quote do  
        ...>   def func do: "doctest"    
        ...> end  
        {:def, [context: SumMagTest, import: Kernel],
          [{:func, [context: SumMagTest], [[do: "doctest"]]}]}

        iiex> quote do
        ...>   defmmf do
        ...>     def func do: "doctest"
        ...>   end
        ...> end 
        
  """
  def melt_block([ do: { :__block__, [], []    } ]), do: []
  def melt_block([ do: { :__block__, [], funcs } ]), do: funcs
  def melt_block([ do: func]), do: [func] 

  def iced_block([func]), do: [ do: func]
  def iced_block(funcs), do: [ do: { :__block__, [], funcs } ]

  # ASTを再帰的に走査して，パイプライン演算子のネストを検知する\n
  # 最低2個連なっていれば，Map/Map Fusionを試みる\n
  # find nests of pipe line operator by recursive.\n
  # If ast have more than 2 nest layer, try optimizing expressions with Map/Map Fusion\n
  def exploration(
    {:|>, meta1,[ 
        {:|>, meta2, args} = left, 
        right
    ]} = input) do
      input |> Opt.inspect(label: "verify")
      
      left 
      |> exploration 
      |> Opt.inspect(label: "explorated")

      # argsにEnum.mapを含むか？
      # if left_args_has_enum_map and right_is_enum_map do
      # ret = merge_functions(left |> mapping , right |> mapping )
      # else
      #   input
      # end

      # ret |> Opt.inspect(label: "explorating")
      input
  end

  def exploration(
    {:|>, meta1,[ 
      literal, 
      right
    ]} = input) do 

    input |> Opt.inspect(label: "Innermost elements of AST")
    
    {:ok, input}
  end

  # version keyword-list 
  def exploration(
    [
      {:tree, dungeon},
      {:enum_map },
      {:func_meta, func_meta},
      {:func,      function},
      {:level, }
    ]),  do: dungeon |> exploration
 
  # defp exploration({:|>, _, literal}, acc) do
  #   case literal do
  #     [ {:|>, _, _}, _child ] -> 
  #       literal |> IO.inspect(label: "literal")
  #       # buf = child |> 
  #      _  -> 
  #       literal |> IO.inspect(label: "literal")
  #   end
  # end

  def quoted_var?({:&, _, [1]}) do
    true
  end

  def quoted_var?({atom, meta, nil}) 
    when atom |> is_atom do
      true
  end

  def quoted_var?(other) when other |> is_number, do: true

  def quoted_var?(other), do: nil

  def divide_meta(ast) do
    ast
    |> Macro.prewalk([], fn 
      ({atom, meta, tree}, acc) -> {{atom, tree}, acc ++ meta}
      (other, acc) -> {other, acc}
    end)
  end
  
  def delete_meta(ast) do
    ast
    |> Macro.prewalk( fn 
      {atom, meta, tree} -> {atom, tree}
      other -> other
    end)
  end
end