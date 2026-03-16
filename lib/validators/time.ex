defmodule EctoCommons.TimeValidator do
  @moduledoc ~S"""
  This module provides validators for `Time`s.

  You can use the following checks:

    * `:is` to check if a `Time` is exactly some `Time`. You can also provide a `:delta` option (in seconds)
       to specify a delta around which the `Time` is still considered identical.
    * `:before` to check if a `Time` is before some `Time`
    * `:after` to check if a `Time` is after some `Time`

  You can also combine the given checks for complex checks. Errors won't be stacked though, the first error
  encountered will be returned and subsequent checks will be skipped.
  If you want to check everything at once, you'll need to call this validator multiple times.

  Also, instead of providing a `Time`, you can also provide some special atoms:

    * `:utc_now` will compare the given `Time` with the `Time` at runtime, by calling `Time.utc_now()`.

  ## Example:

      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start)
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [], data: %{}, valid?: true, ...>

      # Using :is to ensure a time is identical to another time
      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, is: ~T[12:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, is: ~T[13:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [meeting_start: {"should be %{is}.", [validation: :time, kind: :is]}], data: %{}, valid?: false, ...>

      # Using :is with :delta to ensure a time is near another another time
      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, is: ~T[12:15:01], delta: 900)
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[13:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, is: ~T[12:01:01], delta: 900)
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[13:01:01]}, errors: [meeting_start: {"should be %{is}.", [validation: :time, kind: :is]}], data: %{}, valid?: false, ...>

      # Using :before to ensure time is before given time
      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, before: ~T[13:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, before: ~T[11:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [meeting_start: {"should be before %{before}.", [validation: :time, kind: :before]}], data: %{}, valid?: false, ...>

      # Using :after to ensure time is after given time
      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, after: ~T[11:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{meeting_start: :time}
      iex> params = %{meeting_start: ~T[12:01:01]}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_time(:meeting_start, after: ~T[13:01:01])
      #Ecto.Changeset<action: nil, changes: %{meeting_start: ~T[12:01:01]}, errors: [meeting_start: {"should be after %{after}.", [validation: :time, kind: :after]}], data: %{}, valid?: false, ...>

  """

  import Ecto.Changeset

  def validate_time(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:time, opts}, fn
      _, value ->
        is = get_validation_value(opts[:is])
        afterr = get_validation_value(opts[:after])
        before = get_validation_value(opts[:before])

        error =
          (is && wrong_time(value, is, opts[:delta], opts)) ||
            (afterr && too_soon(value, afterr, opts)) ||
            (before && too_late(value, before, opts))

        if error, do: [{field, error}], else: []
    end)
  end

  defp wrong_time(%Time{} = value, value, _delta, _opts), do: nil

  defp wrong_time(%Time{} = value, is, nil, opts) do
    case Time.compare(value, is) do
      :eq -> nil
      _ -> {message(opts, :message, "should be %{is}."), validation: :time, kind: :is}
    end
  end

  defp wrong_time(%Time{} = value, is, delta, opts) do
    case Time.compare(value, is) do
      :eq ->
        nil

      _ ->
        case abs(Time.diff(value, is)) do
          val when val > delta ->
            {message(opts, :message, "should be %{is}."), validation: :time, kind: :is}

          _ ->
            nil
        end
    end
  end

  defp too_soon(%Time{} = value, value, _opts), do: nil

  defp too_soon(%Time{} = value, afterr, opts) do
    case Time.compare(value, afterr) do
      :gt -> nil
      _ -> {message(opts, :message, "should be after %{after}."), validation: :time, kind: :after}
    end
  end

  defp too_late(%Time{} = value, value, _opts), do: nil

  defp too_late(%Time{} = value, before, opts) do
    case Time.compare(value, before) do
      :lt -> nil
      _ -> {message(opts, :message, "should be before %{before}."), validation: :time, kind: :before}
    end
  end

  defp get_validation_value(nil), do: nil
  defp get_validation_value(:utc_now), do: Time.utc_now()
  defp get_validation_value(%Time{} = val), do: val

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
