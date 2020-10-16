defmodule EctoCommons.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :ecto_commons,
      version: @version,
      name: "Ecto Commons",
      description: description(),
      source_url: "https://github.com/achedeuzot/ecto_commons",
      homepage_url: "http://hexdocs.pm/ecto_commons",
      package: package(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,

      # Test coverage:
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Type checking
      dialyzer: [
        plt_core_path: "_build/#{Mix.env()}",
        plt_add_deps: :apps_direct,
        plt_ignore_apps: [:earmark, :benchee, :ex_doc]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.4"},

      # Used by email validator
      {:burnex, "~> 2.0"},
      # Used by Luhn validator
      {:luhn, "~> 0.3.0"},
      # Used by phone number validator
      {:ex_phone_number, "~> 0.2"},

      # Docs:
      {:ex_doc, "~> 0.21", only: :dev},
      {:earmark, "~> 1.3", only: :dev},

      # Testing:
      {:excoveralls, "~> 0.11", only: :test},

      # Benchmarking
      {:benchee, "~> 1.0", only: :dev},

      # Type checking
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},

      # Lint:
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo_contrib, "~> 0.2.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [source_ref: "v#{@version}", main: "readme", extras: docs_extras()]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp description do
    "Common helpers for Ecto: validators, formatters, etc."
  end

  defp package do
    [
      name: :ecto_commons,
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Klemen Sever"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/achedeuzot/ecto_commons"}
    ]
  end
end
