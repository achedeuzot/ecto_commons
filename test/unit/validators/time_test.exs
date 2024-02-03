defmodule EctoCommons.TimeValidatorTest do
  use ExUnit.Case, async: true

  import EctoCommons.TimeValidator
  doctest EctoCommons.TimeValidator, import: true

  @parameters_before [
    # Happy path
    {~T[11:01:01], ~T[12:01:01], []},
    {~T[00:00:01Z], :utc_now, []},
    {~U[2016-05-24 11:00:00Z], ~T[12:01:01], []},
    # Equal date does not trigger error, it has to be strictly lower.
    {~T[12:01:01], ~T[12:01:01], []},

    # Sad path
    {~T[13:01:01], ~T[12:01:01],
     [{:meeting_start, {"should be before %{before}.", [validation: :time, kind: :before]}}]},
    {~U[2016-05-24 13:00:00Z], ~T[12:01:01],
     [{:meeting_start, {"should be before %{before}.", [validation: :time, kind: :before]}}]}
  ]

  for {input, before, expected_errors} <- @parameters_before do
    test "validate_time with #{input} is before #{before}, returns errors as #{inspect(expected_errors)}" do
      types = %{meeting_start: :time}
      params = %{meeting_start: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_time(:meeting_start, before: unquote(Macro.escape(before)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  @parameters_after [
    # Happy path
    {~T[13:01:01], ~T[12:01:01], []},
    {~T[23:59:59Z], :utc_now, []},
    {~U[2016-05-24 13:00:00Z], ~T[12:01:01], []},
    # Equal date does not trigger error, it has to be strictly greatly.
    {~T[12:01:01], ~T[12:01:01], []},

    # Sad path
    {~T[11:01:01], ~T[12:01:01],
     [{:meeting_start, {"should be after %{after}.", [validation: :time, kind: :after]}}]},
    {~U[2016-05-24 11:00:00Z], ~T[12:01:01],
     [{:meeting_start, {"should be after %{after}.", [validation: :time, kind: :after]}}]}
  ]

  for {input, afterr, expected_errors} <- @parameters_after do
    test "validate_time with #{input} is after #{afterr}, returns errors as #{inspect(expected_errors)}" do
      types = %{meeting_start: :time}
      params = %{meeting_start: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_time(:meeting_start, after: unquote(Macro.escape(afterr)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  test "validate_time after and before only returns one of the errors" do
    types = %{meeting_start: :time}
    params = %{meeting_start: ~T[11:01:01]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_time(:meeting_start, after: ~T[12:01:01], before: ~T[12:01:01])

    assert [{:meeting_start, {"should be after %{after}.", [validation: :time, kind: :after]}}] ==
             result.errors
  end
end
