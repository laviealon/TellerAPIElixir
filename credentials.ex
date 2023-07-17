defmodule Credentials do
  @moduledoc """
  A credentials object to hold all the necessary information to make a request to the Teller API.
  Some attributes may be redundant depending on the request being made. Credentials objects only store
  information that must persist between requests. For example, a user's password is not stored in a
  credentials object because it is only needed for the initial request to sign in.

  Attributes:
    teller_mission (str): The teller mission header.
    f_token (str): The f-token header.
    r_token (str): The r-token header.
    s_token (str): The s-token header.
    a_token (str): The a-token header.
    username (str): The user's username.
    device_id (str): The user's device id.
    mfa_id (str): The mfa id of the user, specific to the mfa flow.
  """

  defstruct [:teller_mission, :f_token, :r_token, :s_token, :a_token, :username, :device_id, :mfa_id]

  def update(%Credentials{} = credentials, response \\ nil, opts) do
    struct(credentials, opts)
  end

  def to_string(%Credentials{} = credentials) do
    Enum.map(credentials, fn {k, v} -> "#{k}: #{v}\n" end)
    |> Enum.join()
  end
end
