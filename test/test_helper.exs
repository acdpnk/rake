Dynamo.under_test(Rake.Dynamo)
Dynamo.Loader.enable
ExUnit.start

defmodule Rake.TestCase do
  use ExUnit.CaseTemplate

  # Enable code reloading on test cases
  setup do
    Dynamo.Loader.enable
    :ok
  end
end
