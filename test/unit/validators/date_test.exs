defmodule EctoCommons.DateValidatorTest do
  use ExUnit.Case, async: true
  import EctoCommons.DateValidator

  doctest EctoCommons.DateValidator, import: true

  @parameters_before [
    # Happy path
    {~D[2015-05-20], ~D[2015-05-24], []},
    {~D[2015-05-20], :utc_today, []},
    # Equal date does not trigger error, it has to be strictly lower.
    {~D[2015-05-24], ~D[2015-05-24], []},

    # Sad path
    {~D[2015-05-25], ~D[2015-05-24],
     [
       {:birthdate,
        {"should be before %{before}.",
         [validation: :date, kind: :before, before: ~D[2015-05-24]]}}
     ]}
  ]

  for {input, before, expected_errors} <- @parameters_before do
    test "validate_date with #{input} is before #{before}, returns errors as #{inspect(expected_errors)}" do
      types = %{birthdate: :date}
      params = %{birthdate: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_date(:birthdate, before: unquote(Macro.escape(before)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  @parameters_after [
    # Happy path
    {~D[2015-05-25], ~D[2015-05-24], []},
    {~D[2999-05-25], :utc_today, []},
    # Equal date does not trigger error, it has to be strictly greatly.
    {~D[2015-05-24], ~D[2015-05-24], []},

    # Sad path
    {~D[2015-05-23], ~D[2015-05-24],
     [
       {:birthdate,
        {"should be after %{after}.", [validation: :date, kind: :after, after: ~D[2015-05-24]]}}
     ]}
  ]

  for {input, afterr, expected_errors} <- @parameters_after do
    test "validate_date with #{input} is after #{afterr}, returns errors as #{inspect(expected_errors)}" do
      types = %{birthdate: :date}
      params = %{birthdate: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_date(:birthdate, after: unquote(Macro.escape(afterr)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  test "validate_date after and before only returns one of the errors" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[2015-05-24]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, after: ~D[2015-05-25], before: ~D[2015-05-25])

    assert [
             {:birthdate,
              {"should be after %{after}.",
               [validation: :date, kind: :after, after: ~D[2015-05-25]]}}
           ] ==
             result.errors
  end

  test "validate_date before utc_today with valid data" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[2016-05-24]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, before: :utc_today)

    assert [] == result.errors
  end

  test "validate_date before utc_today with invalid data" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[3000-05-24]}
    date = Date.utc_today()

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, before: :utc_today)

    assert [
             birthdate: {
               "should be before %{before}.",
               [validation: :date, kind: :before, before: date]
             }
           ] == result.errors
  end

  test "validate_date after utc_today with valid data" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[3000-05-24]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, after: :utc_today)

    assert [] == result.errors
  end

  test "validate_date after utc_today with invalid data" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[1000-05-24]}
    date = Date.utc_today()

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, after: :utc_today)

    assert [
             {:birthdate,
              {
                "should be after %{after}.",
                [validation: :date, kind: :after, after: date]
              }}
           ] == result.errors
  end
end
