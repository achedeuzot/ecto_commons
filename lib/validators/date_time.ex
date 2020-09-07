defmodule EctoCommons.DateTimeValidator do
  @moduledoc ~S"""
  This module provides validators for `DateTime`s.

  You can use the following checks:

    * `:is` to check if a `DateTime` is exactly some `DateTime`. You can also provide a `:delta` option (in seconds)
       to specify a delta around which the `DateTime` is still considered identical.
    * `:before` to check if a `DateTime` is before some `DateTime`
    * `:after` to check if a `DateTime` is after some `DateTime`

  You can also combine the given checks for complex checks. Errors won't be stacked though, the first error
  encountered will be returned and subsequent checks will be skipped.
  If you want to check everything at once, you'll need to call this validator multiple times.

  Also, instead of providing a `DateTime`, you can also provide some special atoms:

    * `:utc_now` will compare the given `DateTime` with the `DateTime` at runtime, by calling `DateTime.utc_now()`.

  ## Example:

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      # Using :is to ensure a date is identical to another date
      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, is: ~U[2016-05-24 13:26:08Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, is: ~U[2017-05-24 13:26:08Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [birthdate: {"should be %{is}.", [validation: :datetime, kind: :is]}], data: %{}, valid?: false>

      # Using :is with :delta to ensure a date is near another another date
      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, is: ~U[2016-05-24 13:46:08Z], delta: 3600)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 15:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, is: ~U[2016-05-24 13:26:08Z], delta: 3600)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 15:26:08Z]}, errors: [birthdate: {"should be %{is}.", [validation: :datetime, kind: :is]}], data: %{}, valid?: false>

      # Using :before to ensure date is before given date
      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, before: ~U[2017-05-24 00:00:00Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, before: ~U[2015-05-24 00:00:00Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [birthdate: {"should be before %{before}.", [validation: :datetime, kind: :before]}], data: %{}, valid?: false>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, before: :utc_now)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[3000-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, before: :utc_now)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[3000-05-24 13:26:08Z]}, errors: [birthdate: {"should be before %{before}.", [validation: :datetime, kind: :before]}], data: %{}, valid?: false>

      # Using :after to ensure date is after given date
      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, after: ~U[2015-05-24 00:00:00Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[2016-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, after: ~U[2017-05-24 00:00:00Z])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[2016-05-24 13:26:08Z]}, errors: [birthdate: {"should be after %{after}.", [validation: :datetime, kind: :after]}], data: %{}, valid?: false>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[3000-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, after: :utc_now)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[3000-05-24 13:26:08Z]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :utc_datetime}
      iex> params = %{birthdate: ~U[1000-05-24 13:26:08Z]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_datetime(:birthdate, after: :utc_now)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~U[1000-05-24 13:26:08Z]}, errors: [birthdate: {"should be after %{after}.", [validation: :datetime, kind: :after]}], data: %{}, valid?: false>

  """

  import Ecto.Changeset

  def validate_datetime(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:datetime, opts}, fn
      _, value ->
        is = get_validation_value(opts[:is])
        afterr = get_validation_value(opts[:after])
        before = get_validation_value(opts[:before])

        error =
          (is && wrong_datetime(value, is, opts[:delta], opts)) ||
            (afterr && too_soon(value, afterr, opts)) ||
            (before && too_late(value, before, opts))

        if error, do: [{field, error}], else: []
    end)
  end

  defp wrong_datetime(%DateTime{} = value, value, _delta, _opts), do: nil

  defp wrong_datetime(%DateTime{} = value, is, nil, opts) do
    case DateTime.compare(value, is) do
      :eq -> nil
      _ -> {message(opts, "should be %{is}."), validation: :datetime, kind: :is}
    end
  end

  defp wrong_datetime(%DateTime{} = value, is, delta, opts) do
    case DateTime.compare(value, is) do
      :eq ->
        nil

      _ ->
        case abs(DateTime.diff(value, is, :second)) do
          val when val > delta ->
            {message(opts, "should be %{is}."), validation: :datetime, kind: :is}

          _ ->
            nil
        end
    end
  end

  defp too_soon(%DateTime{} = value, value, _opts), do: nil

  defp too_soon(%DateTime{} = value, afterr, opts) do
    case DateTime.compare(value, afterr) do
      :gt -> nil
      _ -> {message(opts, "should be after %{after}."), validation: :datetime, kind: :after}
    end
  end

  defp too_late(%DateTime{} = value, value, _opts), do: nil

  defp too_late(%DateTime{} = value, before, opts) do
    case DateTime.compare(value, before) do
      :lt -> nil
      _ -> {message(opts, "should be before %{before}."), validation: :datetime, kind: :before}
    end
  end

  defp get_validation_value(nil), do: nil
  defp get_validation_value(:utc_now), do: DateTime.utc_now()
  defp get_validation_value(%DateTime{} = val), do: val

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
