defmodule EctoCommons.StringValidator do
  @moduledoc ~S"""
  This module provides validation for String / Text values

  The following validators are available:

    * `validate_has_prefix/3` which will check if a given field is prefixed
      by some given fixed or dynamic string

  ## Example:

      # Simple prefix
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: "private")
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [], data: %{}, valid?: true>

      # Prefix with separator
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: "private", separator: "|")
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [], data: %{}, valid?: true>

      # Wrong prefix
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: "provider")
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [token: {"is not prefixed by %{prefix}.", [validation: :has_prefix]}], data: %{}, valid?: false>

      # Correct prefix but wrong separator
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: "private", separator: "_")
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [token: {"is not prefixed by %{prefix}.", [validation: :has_prefix]}], data: %{}, valid?: false>

      # Dynamic prefix from function which is correct
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: fn _chgst, _opts -> "private" end)
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [], data: %{}, valid?: true>

      # Dynamic prefix from another changeset field
      iex> types = %{token: :string, provider: :string}
      iex> params = %{token: "iamsvc|some-random-string-id", provider: "iamsvc"}
      iex> changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :provider) end)
      iex> changeset.changes.provider
      "iamsvc"
      iex> changeset.changes.token
      "iamsvc|some-random-string-id"
      iex> changeset.valid?
      true

      # Dynamic prefix from another changeset field
      iex> types = %{token: :string, provider: :string}
      iex> params = %{token: "some-random-string-id", provider: nil}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: fn chgst, _opts -> Ecto.Changeset.get_field(chgst, :provider) end)
      #Ecto.Changeset<action: nil, changes: %{token: "some-random-string-id"}, errors: [], data: %{}, valid?: true>

      # Dynamic prefix from function, which fails
      iex> types = %{token: :string}
      iex> params = %{token: "private|some-random-string-id"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_has_prefix(:token, prefix: fn _chgst, _opts -> "test" end)
      #Ecto.Changeset<action: nil, changes: %{token: "private|some-random-string-id"}, errors: [token: {"is not prefixed by %{prefix}.", [validation: :has_prefix]}], data: %{}, valid?: false>

  """

  import Ecto.Changeset

  def validate_has_prefix(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:has_prefix, opts}, fn _, value ->
      prefix = get_prefix(changeset, opts[:prefix], opts)

      error = prefix && wrong_prefix(value, prefix, opts)

      if error, do: [{field, error}], else: []
    end)
  end

  defp get_prefix(changeset, prefix, opts) when is_function(prefix),
    do: get_prefix(changeset, prefix.(changeset, opts), opts)

  defp get_prefix(changeset, prefix, opts) when is_nil(prefix),
    do: get_prefix(changeset, "", opts)

  defp get_prefix(_changeset, prefix, opts) do
    if opts[:separator] != nil && String.length(opts[:separator]) > 0 do
      prefix <> opts[:separator]
    else
      prefix
    end
  end

  defp wrong_prefix(value, prefix, opts) do
    unless String.starts_with?(value, prefix) do
      {message(opts, :message, "is not prefixed by %{prefix}."), validation: :has_prefix}
    else
      nil
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
