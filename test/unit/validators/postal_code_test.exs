defmodule EctoCommons.PostalCodeValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.PostalCodeValidator, import: true
  alias EctoCommons.PostalCodeValidator

  describe "French postal codes" do
    @fr_valid_codes ["81100", "42380", "81570", "97110", "20090", "75001", "75 008"]
    @fr_invalid_codes ["99130", "A8100", "42", "2A500"]

    for code <- @fr_valid_codes do
      test "valid code: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: "fr")

        assert result.valid? == true
      end
    end

    for code <- @fr_invalid_codes do
      test "invalid code: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: "fr")

        assert result.valid? == false
      end
    end
  end

  describe "Great Britain postal_code" do
    @gb_valid_codes [
      "W1J7NT",
      "DE128HJ",
      "HD75UZ",
      "W21JB",
      "SW1W 0NY",
      "PO16 7GZ",
      "GU16 7HF",
      "L1 8JQ"
    ]
    @gb_invalid_codes ["A1380", "BC500"]

    for code <- @gb_valid_codes do
      test "valid code: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: "gb")

        assert result.valid? == true
      end
    end

    for code <- @gb_invalid_codes do
      test "invalid code: #{code}" do
        types = %{postal_code: :string}
        params = %{postal_code: unquote(code)}

        result =
          Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
          |> PostalCodeValidator.validate_postal_code(:postal_code, country: "gb")

        assert result.valid? == false
      end
    end
  end
end
