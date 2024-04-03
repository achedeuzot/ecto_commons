defmodule EctoCommons.PostalCodeValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.PostalCodeValidator, import: true
  alias EctoCommons.PostalCodeValidator

  describe "postal codes" do
    @valid_codes [
      # France
      {"fr", "81100"},
      {"fr", "42380"},
      {"fr", "81570"},
      {"fr", "97110"},
      {"fr", "20090"},
      {"fr", "75001"},
      {"fr", "75 008"},

      # Great britain
      {"gb", "W1J7NT"},
      {"gb", "DE128HJ"},
      {"gb", "HD75UZ"},
      {"gb", "W21JB"},
      {"gb", "SW1W 0NY"},
      {"gb", "PO16 7GZ"},
      {"gb", "GU16 7HF"},
      {"gb", "L1 8JQ"},

      # European crountries with prefix on postal codes
      # See https://publications.europa.eu/code/en/en-390105.htm
      # Luxemburg
      {"fi", "FI-12345"},
      {"fi", "AX-12345"},
      {"hr", "HR-12345"},
      {"lt", "LT-12345"},
      {"lu", "1234"},
      {"lu", "L-1234"},
      {"lv", "LV-1234"},
      {"se", "SE-12345"},
      {"si", "SI-1234"}
    ]
    @invalid_codes [
      # France
      {"fr", "99130"},
      {"fr", "A8100"},
      {"fr", "42"},
      {"fr", "2A500"},

      # Great Britain
      {"gb", "A1380"},
      {"gb", "BC500"},

      # Luxemburg
      {"fi", "FI12345"},
      {"fi", "F12345"},
      {"fi", "AX12345"},
      {"fi", "A12345"},
      {"hr", "HR12345"},
      {"hr", "H12345"},
      {"lt", "LT12345"},
      {"lt", "L12345"},
      {"lu", "L1234"},
      {"lv", "LV1234"},
      {"se", "SE12345"},
      {"se", "S12345"},
      {"si", "SI1234"},
      {"si", "S1234"}
    ]

    for {country, code} <- @valid_codes do
      test "valid code for country #{country}: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: unquote(country))

        assert result.valid? == true
      end
    end

    for {country, code} <- @invalid_codes do
      test "invalid code for country #{country}: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: unquote(country))

        assert result.valid? == false
      end
    end

    test "unknown country code for postal code" do
      types = %{postal_code: :string}
      params = %{postal_code: "12345"}

      assert_raise ArgumentError, "Unknown country code for validate_postal_code", fn ->
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> PostalCodeValidator.validate_postal_code(:postal_code, country: "xx", raise_if_unknown_country: true)
      end
    end

    test "reject on unknown country code only if option is given" do
      types = %{postal_code: :string}
      params = %{postal_code: "12345"}

      result = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> PostalCodeValidator.validate_postal_code(:postal_code, country: "xx")

      assert result.valid? == true

      result = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> PostalCodeValidator.validate_postal_code(:postal_code, country: "xx", reject_if_unknown_country: true)

      assert result.valid? == false
    end
  end
end
