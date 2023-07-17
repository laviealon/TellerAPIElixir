defmodule Teller do
  @api_base_url "https://test.teller.engineering"
  @user_agent "Teller Bank iOS 2.0"
  @api_key "HowManyGenServersDoesItTakeToCrackTheBank?"

  def signin(credentials, password) do
    headers = %{
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "content-type" => "application/json",
      "accept" => "application/json"
    }
    payload = %{
      "p" => password,
      "username" => credentials.username
    }
    HTTPoison.post(@api_base_url <> "/signin", Jason.encode!(payload), headers)
  end

  def request_mfa_method(credentials, method_id) do
    headers = %{
      "teller-mission" => teller_mission_check(credentials.teller_mission),
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "r-token" => credentials.r_token,
      "f-token" => credentials.f_token,
      "content-type" => "application/json",
      "accept" => "application/json"
    }
    payload = %{
      "device_id" => method_id
    }
    HTTPoison.post(@api_base_url <> "/signin/mfa", Jason.encode!(payload), headers)
  end

  def verify_mfa(credentials, mfa_code) do
    headers = %{
      "teller-mission" => teller_mission_check(credentials.teller_mission),
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "r-token" => credentials.r_token,
      "f-token" => credentials.f_token,
      "content-type" => "application/json",
      "accept" => "application/json"
    }
    payload = %{
      "code" => mfa_code
    }
    HTTPoison.post(@api_base_url <> "/signin/mfa/verify", Jason.encode!(payload), headers)
  end

  def get_transactions(credentials, account_id) do
    headers = %{
      "teller-mission" => teller_mission_check(credentials.teller_mission),
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "r-token" => credentials.r_token,
      "f-token" => credentials.f_token,
      "s-token" => credentials.s_token,
      "accept" => "application/json"
    }
    HTTPoison.get(@api_base_url <> "/accounts/#{account_id}/transactions", headers)
  end

  def get_balances(credentials, account_id) do
    headers = %{
    "teller-mission" => teller_mission_check(credentials.teller_mission),
    "user-agent" => @user_agent,
    "api-key" => @api_key,
    "device-id" => credentials.device_id,
    "r-token" => credentials.r_token,
    "f-token" => credentials.f_token,
    "s-token" => credentials.s_token,
    "accept" => "application/json"
    }
    HTTPoison.get(@api_base_url <> "/accounts/#{account_id}/balances", headers)
  end

  def get_details(credentials, account_id) do
    headers = %{
      "teller-mission" => teller_mission_check(credentials.teller_mission),
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "r-token" => credentials.r_token,
      "f-token" => credentials.f_token,
      "s-token" => credentials.s_token,
      "accept" => "application/json"
    }
    HTTPoison.get(@api_base_url <> "/accounts/#{account_id}/details", headers)
  end

  def reauthenticate(credentials) do
    headers = %{
      "user-agent" => @user_agent,
      "api-key" => @api_key,
      "device-id" => credentials.device_id,
      "content-type" => "application/json",
      "accept" => "application/json"
    }
    payload = %{
      "token" => credentials.a_token
    }
    HTTPoison.post(@api_base_url <> "/signin/token", Jason.encode!(payload), headers)
  end

  defp teller_mission_check(teller_mission) do
    if teller_mission == 'https://blog.teller.io/2021/06/21/our-mission.html' do
      'accepted!'
    else
      'rejected!'
    end
  end

  def find_symbol(f_token_spec) do
    symbol_start = -1
    symbol_end = -1

    for {char, i} <- Enum.with_index(f_token_spec) do
      if !String.match?(char, ~r/[\w-]/) do
        if symbol_start == -1 do
          symbol_start = i
        end
        symbol_end = i
      else
        if symbol_start != -1 do
          break
        end
      end
    end

    if symbol_start != -1 do
      String.slice(f_token_spec, symbol_start..symbol_end)
    else
      if String.contains?(f_token_spec, "--") do
        "--"
      else
        raise "invalid f-token-spec"
      end
    end
  end

  def extract_f_token(f_token_spec, username, f_request_id, device_id, api_key) do
    var_dict = %{
      "username" => username,
      "last-request-id" => f_request_id,
      "device-id" => device_id,
      "api-key" => api_key
    }

    f_token_spec = Base.decode64!(f_token_spec) |> to_string()

    cleaned_f_token_spec = String.slice(f_token_spec, 15..-2)

    split_symb = find_symbol(cleaned_f_token_spec)

    spec_parts = String.split(cleaned_f_token_spec, split_symb)

    final_string =
      Enum.reduce(spec_parts, "", fn part, acc ->
        if Map.has_key?(var_dict, part) do
          acc <> var_dict[part] <> (if part != List.last(spec_parts), do: split_symb, else: "")
        else
          acc
        end
      end)

    final_string =
      :crypto.hash(:sha256, final_string)
      |> Base.encode64()
      |> to_string()

    String.slice(final_string, 0..-2)
  end

  def decrypt_account_number(cipher_data, enc_key) do
    key = :erlang.binary_to_term(Base.decode64!(enc_key))[:key] |> Base.decode64!()
    [ct, nonce, t] = String.split(cipher_data, find_symbol(cipher_data)) |> Enum.map(&Base.decode64!/1)
    :crypto.crypto_one_time_aead(:aes_gcm, key, nonce, ct, "", :decrypt)
    |> to_string()
  end
end
