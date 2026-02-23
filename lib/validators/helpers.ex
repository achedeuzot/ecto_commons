defmodule EctoCommons.Helpers do
  @moduledoc """
  Contains helpers related to Ecto.

  See functions contained in the module for more info.
  """

  @doc """
  This allows for validating multiple fields with the same validator function
  with the same options for all fields.

  ## Example

      iex> types = %{first_name: :string, last_name: :string}
      iex> params = %{first_name: "John", last_name: "Doe"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_many(
      ...>   [:first_name, :last_name],
      ...>   &Ecto.Changeset.validate_length/3,
      ...>   min: 2,
      ...>   max: 20
      ...> )
      #Ecto.Changeset<action: nil, changes: %{first_name: "John", last_name: "Doe"}, errors: [], data: %{}, valid?: true, ...>

      iex> types = %{first_name: :string, last_name: :string}
      iex> params = %{first_name: "J", last_name: "DoppelgängerDoppelgänger"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_many(
      ...>   [:first_name, :last_name],
      ...>   &Ecto.Changeset.validate_length/3,
      ...>   min: 2,
      ...>   max: 20,
      ...>   message: "this field is invalid"
      ...> )
      #Ecto.Changeset<action: nil, changes: %{first_name: \"J\", last_name: \"DoppelgängerDoppelgänger\"}, errors: [last_name: {\"this field is invalid\", [count: 20, validation: :length, kind: :max, type: :string]}, first_name: {\"this field is invalid\", [count: 2, validation: :length, kind: :min, type: :string]}], data: %{}, valid?: false, ...>
  """
  def validate_many(changeset, fields, validator, opts \\ []) when is_list(fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      args = [changeset, field | [opts]]
      apply(validator, args)
    end)
  end
end
