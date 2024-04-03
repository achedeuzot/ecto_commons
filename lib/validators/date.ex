defmodule EctoCommons.DateValidator do
  @moduledoc ~S"""
  This module provides validators for `Date`s.

  You can use the following checks:

    * `:is` to check if a `Date` is exactly some `Date`. You can also provide a `:delta` option (in days)
       to specify a delta around which the `Date` is still considered identical.
    * `:before` to check if a `Date` is before some `Date`
    * `:after` to check if a `Date` is after some `Date`

  You can also combine the given checks for complex checks. Errors won't be stacked though, the first error
  encountered will be returned and subsequent checks will be skipped.
  If you want to check everything at once, you'll need to call this validator multiple times.

  Also, instead of providing a `Date`, you can also provide some special atoms:

    * `:utc_today` will compare the given `Date` with the `Date` at runtime, by calling `Date.utc_today()`.

  ## Example:

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true>

      # Using :is to ensure a date is identical to another date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be %{is}.", [validation: :date, kind: :is]}], data: %{}, valid?: false>

      # Using :is with :delta to ensure a date is near another another date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-20]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24], delta: 7)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-20]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-04-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24], delta: 7)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-04-24]}, errors: [birthdate: {"should be %{is}.", [validation: :date, kind: :is]}], data: %{}, valid?: false>

      # Using :before to ensure date is before given date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: ~D[2015-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be before %{before}.", [validation: :date, kind: :before]}], data: %{}, valid?: false>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: :utc_today)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[3000-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: :utc_today)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[3000-05-24]}, errors: [birthdate: {"should be before %{before}.", [validation: :date, kind: :before]}], data: %{}, valid?: false>

      # Using :after to ensure date is after given date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: ~D[2015-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be after %{after}.", [validation: :date, kind: :after]}], data: %{}, valid?: false>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[3000-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: :utc_today)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[3000-05-24]}, errors: [], data: %{}, valid?: true>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[1000-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: :utc_today)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[1000-05-24]}, errors: [birthdate: {"should be after %{after}.", [validation: :date, kind: :after]}], data: %{}, valid?: false>

  """

  import Ecto.Changeset

  def validate_date(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:date, opts}, fn
      _, value ->
        is = get_validation_value(opts[:is])
        afterr = get_validation_value(opts[:after])
        before = get_validation_value(opts[:before])

        error =
          (is && wrong_date(value, is, opts[:delta], opts)) ||
            (afterr && too_soon(value, afterr, opts)) ||
            (before && too_late(value, before, opts))

        if error, do: [{field, error}], else: []
    end)
  end

  defp wrong_date(%Date{} = value, value, _delta, _opts), do: nil

  defp wrong_date(%Date{} = value, is, nil, opts) do
    case Date.compare(value, is) do
      :eq -> nil
      _ -> {message(opts, "should be %{is}."), validation: :date, kind: :is}
    end
  end

  defp wrong_date(%Date{} = value, is, delta, opts) do
    case Date.compare(value, is) do
      :eq ->
        nil

      _ ->
        case abs(Date.diff(value, is)) do
          val when val > delta ->
            {message(opts, "should be %{is}."), validation: :date, kind: :is}

          _ ->
            nil
        end
    end
  end

  defp too_soon(%Date{} = value, value, _opts), do: nil

  defp too_soon(%Date{} = value, afterr, opts) do
    case Date.compare(value, afterr) do
      :gt -> nil
      _ -> {message(opts, "should be after %{after}."), validation: :date, kind: :after}
    end
  end

  defp too_late(%Date{} = value, value, _opts), do: nil

  defp too_late(%Date{} = value, before, opts) do
    case Date.compare(value, before) do
      :lt -> nil
      _ -> {message(opts, "should be before %{before}."), validation: :date, kind: :before}
    end
  end

  defp get_validation_value(nil), do: nil
  defp get_validation_value(:utc_today), do: Date.utc_today()
  defp get_validation_value(%Date{} = val), do: val

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
