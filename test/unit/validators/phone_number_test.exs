defmodule EctoCommons.PhoneNumberValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.PhoneNumberValidator, import: true
  alias EctoCommons.PhoneNumberValidator

  describe "Valid phone numbers" do
    @valid_phone_numbers [
      {"044 668 18 00", "CH"},
      {"011 41 44 668 1800", "US"},
      {"(425) 555-0123", "US"},
      {"+1 206 555 0100", "US"},
      {"01 23 45 67 89", "FR"},
      {"+44 113 496 0000", "GB"},
      # Works with country not matching phone number
      {"+33612345678", "US"},
      {"+33612345679", ""},
      {"+33612345680", nil},
      # Noise in string
      {"whatever 044 669 18 00", "CH"}
    ]

    for {phone, country} <- @valid_phone_numbers do
      test "valid phone number: #{phone}" do
        types = %{phone_number: :string}
        params = %{phone_number: unquote(phone)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PhoneNumberValidator.validate_phone_number(:phone_number, country: unquote(country))

        assert result.valid? == true
      end
    end
  end

  describe "Invalid phone numbers" do
    @invalid_phone_numbers [
      # Wrong number
      {"0044234567890", "SI"},
      # Too long
      {"+3341234567890", "FR"},
      # Too short
      {"+334", "FR"}
    ]

    for {phone, country} <- @invalid_phone_numbers do
      test "invalid phone number: #{phone}" do
        types = %{phone_number: :string}
        params = %{phone_number: unquote(phone)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PhoneNumberValidator.validate_phone_number(:phone_number, country: unquote(country))

        assert result.valid? == false
      end
    end
  end
end
