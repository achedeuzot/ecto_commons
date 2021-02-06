defmodule EctoCommons.DateTimeValidatorTest do
  use ExUnit.Case, async: true
  import EctoCommons.DateTimeValidator

  doctest EctoCommons.DateTimeValidator, import: true

  @parameters_before [
    # Happy path
    {~U[2016-05-24 14:00:00Z], ~U[2016-05-24 15:00:00Z], []},
    # Equal datetime does not trigger error, it has to be strictly lower.
    {~U[2016-05-24 15:00:00Z], ~U[2016-05-24 15:00:00Z], []},

    # Sad path
    {~U[2016-05-24 16:00:00Z], ~U[2016-05-24 15:00:00Z],
     [{:birthdate, {"should be before %{before}.", [validation: :datetime, kind: :before]}}]}
  ]

  for {input, before, expected_errors} <- @parameters_before do
    test "validate_datetime with #{input} is before #{before}, returns errors as #{
           inspect(expected_errors)
         }" do
      types = %{birthdate: :utc_datetime}
      params = %{birthdate: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_datetime(:birthdate, before: unquote(Macro.escape(before)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  @parameters_after [
    # Happy path
    {~U[2016-05-24 16:00:00Z], ~U[2016-05-24 15:00:00Z], []},
    # Equal date does not trigger error, it has to be strictly greatly.
    {~U[2016-05-24 15:00:00Z], ~U[2016-05-24 15:00:00Z], []},

    # Sad path
    {~U[2016-05-24 14:00:00Z], ~U[2016-05-24 15:00:00Z],
     [{:birthdate, {"should be after %{after}.", [validation: :datetime, kind: :after]}}]}
  ]

  for {input, afterr, expected_errors} <- @parameters_after do
    test "validate_datetime with #{input} is after #{afterr}, returns errors as #{
           inspect(expected_errors)
         }" do
      types = %{birthdate: :utc_datetime}
      params = %{birthdate: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_datetime(:birthdate, after: unquote(Macro.escape(afterr)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  test "validate_date after and before only returns one of the errors" do
    types = %{birthdate: :utc_datetime}
    params = %{birthdate: ~U[2016-05-24 14:00:00Z]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_datetime(:birthdate,
        after: ~U[2016-05-24 15:00:00Z],
        before: ~U[2016-05-24 15:00:00Z]
      )

    assert [{:birthdate, {"should be after %{after}.", [validation: :datetime, kind: :after]}}] ==
             result.errors
  end
end
