use Mix.Config

# Update the instrumenters so that we can structure Phoenix logs
# For now, do this only for Mix.env == :prod
if Mix.env() == :prod do
  # Update the instrumenters so that we can structure Phoenix logs
  # For now, do this only for Mix.env == :prod
  config :mpnetwork, MpnetworkWeb.Endpoint,
    instrumenters: [Timber.Integrations.PhoenixInstrumenter]

  # Structure Ecto logs
  # Note that I manually prefixed PryIn stuff
  config :mpnetwork, Mpnetwork.Repo,
    loggers: [PryIn.EctoLogger] ++ [{Mpnetwork.CustomTimberLogger, :log, [:info]}]

  # Application.get_env(:mpnetwork, Mpnetwork.Repo)[:loggers]
end

# Use Timber as the logger backend
# Feel free to add additional backends if you want to send your logs to multiple devices.
# Deliver logs via HTTP to the Timber API by using the Timber HTTP backend.
config :logger,
  backends: [Timber.LoggerBackends.HTTP, :console],
  utc_log: true

config :timber, api_key: {:system, "TIMBER_LOGS_KEY"}

# For the following environments, do not log to the Timber service. Instead, log to STDOUT
# and format the logs properly so they are human readable.
environments_to_exclude = [:dev, :test]

if Enum.member?(environments_to_exclude, Mix.env()) do
  # Fall back to the default `:console` backend with the Timber custom formatter
  config :logger,
    backends: [:console],
    utc_log: true

  config :logger, :console,
    format: {Timber.Formatter, :format},
    metadata: [:timber_context, :event, :application, :file, :function, :line, :module]

  config :timber, Timber.Formatter,
    colorize: true,
    format: :logfmt,
    print_timestamps: true,
    print_log_level: true,
    # turn this on to view the additiional metadata
    print_metadata: false
end

# Need help?
# Email us: support@timber.io
# Or, file an issue: https://github.com/timberio/timber-elixir/issues
