defmodule Mpnetwork.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mpnetwork,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      dialyzer: [plt_add_deps: :transitive],
      package: package()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      # applications: [:coherence],
      mod: {Mpnetwork.Application, []},
      extra_applications: [:coherence, :logger, :runtime_tools, :ex_rated]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:distillery, "~> 1.4.0"},
      {:phoenix, "~> 1.3", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10.4"},
      {:phoenix_live_reload, "~> 1.1", only: :dev},
      {:gettext, "~> 0.13"},
      {:cowboy, "~> 1.1.2"},
      # The Coherence guy has been slow about tagging this 0.5.1, so using git SHA for now
      {:coherence, git: "https://github.com/smpallen99/coherence.git", ref: "1f58ba5"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:timex, "~> 3.2.1"},
      {:number, "~> 0.5"},
      {:timber, "~> 2.6"},
      {:ex_image_info, "~> 0.1.1"},
      # provides `mix eliver.bump` for hot prod upgrades
      {:eliver, "~> 2.0"},
      {:cachex, "~> 2.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:swoosh, "~> 0.10"},
      {:phoenix_swoosh, "~> 0.2"},
      # want to replace with another solution asap lol. https://imagetragick.com/
      {:mogrify, "~> 0.5.4"},
      # for easily working with tempfiles
      {:briefly, "~> 0.3"},
      {:ex_crypto, "~> 0.4", override: true},
      {:ecto, "~> 2.2.6", override: true},
      # {:ecto_enum, "~> 1.0"}, # still has a bug. waiting on fix. forked, fixed, and PR'd in meantime:
      {:ecto_enum, git: "https://github.com/pmarreck/ecto_enum.git", branch: "master"},
      {:html_sanitize_ex, "~> 1.3.0-rc3"},
      {:pryin, "~> 1.5"},
      {:dialyxir, "~> 0.5.0", only: [:dev], runtime: false},
      {:quantum, ">= 2.2.5"},
      {:ex_rated, "~> 1.3"},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      licenses: ["EUPL-1.2"],
      maintainers: ["Peter Marreck"],
      links: %{"GitHub" => "https://github.com/pmarreck/mpnetwork"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
