import Config

# Configuration for the flowstone_ai library
# This is only needed for the test environment

if config_env() == :test do
  # Configure hammer for rate limiting (used by altar_ai)
  config :hammer,
    backend:
      {Hammer.Backend.ETS,
       [
         expiry_ms: 60_000 * 60 * 2,
         cleanup_interval_ms: 60_000 * 10
       ]}
end
