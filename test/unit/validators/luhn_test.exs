defmodule EctoCommons.LuhnValidatorTest do
  use ExUnit.Case, async: true
  import EctoCommons.LuhnValidator
  doctest EctoCommons.LuhnValidator, import: true

  test "validate_luhn/2 accepts transformer function" do
    types = %{admin_code: :string}
    params = %{admin_code: "2A0123451"}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_luhn(:admin_code,
        transformer: fn value ->
          if String.starts_with?(value, "2A") do
            String.replace_prefix(value, "2A", "21")
          else
            value
          end
        end
      )

    assert result.errors == []
  end
end
