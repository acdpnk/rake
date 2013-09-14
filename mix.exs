defmodule Rake.Mixfile do
  use Mix.Project

  def project do
    [ app: :rake,
      version: "0.0.1",
      dynamos: [Rake.Dynamo],
      compilers: [:elixir, :dynamo, :app],
      env: [prod: [compile_path: "ebin"]],
      compile_path: "tmp/#{Mix.env}/rake/ebin",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:cowboy, :dynamo],
      mod: { Rake, [] } ]
  end

  defp deps do
    [ { :cowboy, github: "extend/cowboy" },
      { :dynamo, "0.1.0-dev", github: "elixir-lang/dynamo" },
      { :httpotion, github: "myfreeweb/httpotion" },
      { :jsex, github: "talentdeficit/jsex" },
      { :readp, github: "chrifpa/readp"}  ]
  end
end
