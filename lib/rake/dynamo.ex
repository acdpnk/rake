defmodule Rake.Dynamo do
  use Dynamo

  config :dynamo,
    # The environment this Dynamo runs on
    env: Mix.env,

    # The OTP application associated with this Dynamo
    otp_app: :rake,

    # The endpoint to dispatch requests to
    endpoint: ApplicationRouter,

    # The route from which static assets are served
    # You can turn off static assets by setting it to false
    static_route: "/static"

  # Uncomment the lines below to enable the cookie session store
  # config :dynamo,
  #   session_store: Session.CookieStore,
  #   session_options:
  #     [ key: "_rake_session",
  #       secret: "Sh0L9V2sBtQ7d9InwiO9X7Of3nraA1Wt7sgFVYjg7fNJ/OF2gcW68immeWm7ixQI"]

  # Default functionality available in templates
  templates do
    use Dynamo.Helpers
  end
end
