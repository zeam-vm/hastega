defmodule SumMag.MMF.Sample do
  require SumMag.MMF
  import SumMag.MMF

  defmmf do
    # def mmf1(list) do
    #   list
    #   |> Enum.map(& &1 + 1)
    #   |> Enum.map(& &1 * 2)
    # end

    def mmf2(list) do
      list
      |> Enum.map(& &1 + 1)
      |> Enum.map(& &1 + 2)
      |> Enum.map(& &1 + 3)
      |> Enum.map(& &1 + 4)

      # 別コードが挿入されるとASTの形がかわる
    end
  end

  # defmmf do
  #   def func1, do: "test1"
  #   def func2, do: "test2"
  # end

  def pure(list) do
    list
    |> Enum.map(& &1 + 1)
    |> Enum.map(& &1 * 2)
  end
end

defmodule HastegaSample do
  import Hastega
  require Hastega
  defhastega do
    def list_mult_2(list) do
      list
      |> Enum.map(& &1 * 2)
      # |> Enum.map(fn x -> x * 3 end)
    end

    def chunk_every(list) do
      list
      |> Enum.chunk_every(4)
    end
  end
end