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
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true, ...>

      # Using :is to ensure a date is identical to another date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be %{is}.", [validation: :date, kind: :is, is: ~D[2017-05-24]]}], data: %{}, valid?: false, ...>

      # Using :is with :delta to ensure a date is near another another date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-20]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24], delta: 7)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-20]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-04-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, is: ~D[2016-05-24], delta: 7)
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-04-24]}, errors: [birthdate: {"should be %{is}.", [validation: :date, kind: :is, is: ~D[2016-05-24]]}], data: %{}, valid?: false, ...>

      # Using :is with a function to allow for dynamic date comparison
      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[2000-01-31]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :finish, is: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :start) |> Date.add(30) end)
      iex> result.valid?
      true

      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[2000-01-02]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :finish, is: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :start) |> Date.add(30) end)
      iex> result.errors
      [finish: {"should be %{is}.", [validation: :date, kind: :is, is: ~D[2000-01-31]]}]

      # Using :before to ensure date is before given date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, before: ~D[2015-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be before %{before}.", [validation: :date, kind: :before, before: ~D[2015-05-24]]}], data: %{}, valid?: false, ...>

      # Using :before with a function to allow for dynamic date comparison
      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[2000-01-31]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :start, before: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :finish) end)
      iex> result.valid?
      true

      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[1999-01-31]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :start, before: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :finish) end)
      iex> result.errors
      [start: {"should be before %{before}.", [validation: :date, kind: :before, before: ~D[1999-01-31]]}]

      # Using :after to ensure date is after given date
      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: ~D[2015-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{birthdate: :date}
      iex> params = %{birthdate: ~D[2016-05-24]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_date(:birthdate, after: ~D[2017-05-24])
      #Ecto.Changeset<action: nil, changes: %{birthdate: ~D[2016-05-24]}, errors: [birthdate: {"should be after %{after}.", [validation: :date, kind: :after, after: ~D[2017-05-24]]}], data: %{}, valid?: false, ...>

      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[2000-01-31]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :finish, after: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :start) end)
      iex> result.valid?
      true

      iex> types = %{start: :date, finish: :date}
      iex> params = %{start: ~D[2000-01-01], finish: ~D[1999-01-31]}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      iex> result = validate_date(changeset, :finish, after: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :start) end)
      iex> result.errors
      [{:finish, {"should be after %{after}.", [validation: :date, kind: :after, after: ~D[2000-01-01]]}}]

  """

  import Ecto.Changeset

  def validate_date(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:date, opts}, fn
      _, value ->
        is = get_validation_value(changeset, opts[:is], opts)
        afterr = get_validation_value(changeset, opts[:after], opts)
        before = get_validation_value(changeset, opts[:before], opts)

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
      _ -> {message(opts, :message, "should be %{is}."), validation: :date, kind: :is, is: is}
    end
  end

  defp wrong_date(%Date{} = value, is, delta, opts) do
    case Date.compare(value, is) do
      :eq ->
        nil

      _ ->
        case abs(Date.diff(value, is)) do
          val when val > delta ->
            {message(opts, :message, "should be %{is}."), validation: :date, kind: :is, is: is}

          _ ->
            nil
        end
    end
  end

  defp too_soon(%Date{} = value, value, _opts), do: nil

  defp too_soon(%Date{} = value, afterr, opts) do
    case Date.compare(value, afterr) do
      :gt -> nil
      _ -> {message(opts, :message, "should be after %{after}."), validation: :date, kind: :after, after: afterr}
    end
  end

  defp too_late(%Date{} = value, value, _opts), do: nil

  defp too_late(%Date{} = value, before, opts) do
    case Date.compare(value, before) do
      :lt -> nil
      _ -> {message(opts, :message, "should be before %{before}."), validation: :date, kind: :before, before: before}
    end
  end

  defp get_validation_value(_changeset, nil, _opts), do: nil
  defp get_validation_value(_changeset, :utc_today, _opts), do: Date.utc_today()
  defp get_validation_value(_changeset, %Date{} = val, _opts), do: val
  defp get_validation_value(changeset, fun, opts) when is_function(fun), do: fun.(changeset, opts)

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
