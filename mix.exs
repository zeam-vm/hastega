defmodule Hastega.MixProject do
  use Mix.Project

  def project do
    [
      app: :hastega,
      version: "0.0.0",
      elixir: "~> 1.6",
      compilers: [:nif_vec] ++ Mix.compilers,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:benchfella, "~> 0.3.5"},
    ]
  end

  defp description() do
    "Hastega: Hyper Accelerator of Spreading Tasks for Elixir with GPU Activation"
  end

  defp package() do
    [
      name: "hastega",
      maintainers: ["Susumu Yamazaki", "Masakazu Mori", "Yoshihiro Ueno", "Hideki Takase"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/zeam-vm/hastega"}
    ]
  end
end

defmodule Mix.Tasks.Compile.NifVec do
  def run(_) do
    if match? {:win32, _}, :os.type do
      # libpostal does not support Windows unfortunately.
      IO.warn("Windows is not supported.")
      exit(1)
    else
      File.mkdir_p("priv")
      {result, _error_code} = System.cmd("make", ["priv/libnifvec.so"], stderr_to_stdout: true)
      IO.binwrite result
    end
  end
end
