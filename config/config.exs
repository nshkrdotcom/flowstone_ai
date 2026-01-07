import Config

# Configuration for the flowstone_ai library
# Provide a default Hammer backend so examples and dev runtime can start.
config :hammer,
  backend:
    {Hammer.Backend.ETS,
     [
       expiry_ms: 60_000 * 60 * 2,
       cleanup_interval_ms: 60_000 * 10
     ]}
