defmodule EctoCommons.LuhnValidator do
  @moduledoc """
  This ecto validator checks the provided value is valid
  using the Luhn algorithm. This is useful for credit cards and other
  common administrative values.

  The validator accepts an optional `:transformer` function
  that can modify the value before applying the Luhn check. This is
  useful in cases where the input value contains other characters
  or letters instead of only numbers. The transformed value will
  be Luhn-checked without replacing the value provided in the params.

  ## Example:

      iex> types = %{admin_code: :string}
      iex> params = %{admin_code: "740123450"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_luhn(:admin_code)
      #Ecto.Changeset<action: nil, changes: %{admin_code: "740123450"}, errors: [], data: %{}, valid?: true>

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "74012345123456"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_luhn(:admin_id)
      #Ecto.Changeset<action: nil, changes: %{admin_id: "74012345123456"}, errors: [admin_id: {"is not a valid code", [validation: :luhn]}], data: %{}, valid?: false>

      iex> types = %{admin_code: :string}
      iex> params = %{admin_code: "7A0123450"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_luhn(:admin_code, transformer: &(String.replace(&1, "7A", "74")))
      #Ecto.Changeset<action: nil, changes: %{admin_code: "7A0123450"}, errors: [], data: %{}, valid?: true>

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "this is an incorrect value"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_luhn(:admin_id)
      #Ecto.Changeset<action: nil, changes: %{admin_id: "this is an incorrect value"}, errors: [admin_id: {"is not a valid code", [validation: :luhn]}], data: %{}, valid?: false>
  """
  import Ecto.Changeset

  def validate_luhn(changeset, field, opts \\ []) do
    transformer = Keyword.get(opts, :transformer, & &1)

    if transformer && !is_function(transformer),
      do: raise("Given `:transformer` is not a function")

    validate_change(changeset, field, {:luhn, opts}, fn _, value ->
      value = transformer.(value)

      try do
        case Luhn.valid?(value) do
          false ->
            [{field, {message(opts, "is not a valid code"), [validation: :luhn]}}]

          true ->
            []
        end
      rescue
        _e ->
          [{field, {message(opts, "is not a valid code"), [validation: :luhn]}}]
      end
    end)
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
