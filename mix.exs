defmodule Hastega.MixProject do
  use Mix.Project

  def project do
    [
      app: :hastega,
      version: "0.0.0",
      elixir: "~> 1.7",
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
      { :constants,   "~> 0.1.0" },
      { :sum_mag,     "~> 0.0.7" },
      { :ex_doc,      ">= 0.0.0", only: :dev},
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
