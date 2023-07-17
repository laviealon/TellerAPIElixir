ExUnit.start()

defmodule CredentialsTest do
  use ExUnit.Case

  alias Credentials

  test "update/3 updates the struct with the given options" do
    credentials = %Credentials{teller_mission: "mission"}
    updated_credentials = Credentials.update(credentials, nil, teller_mission: "new mission")
    assert updated_credentials.teller_mission == "new mission"
  end
end
