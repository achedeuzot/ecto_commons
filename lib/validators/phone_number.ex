defmodule EctoCommons.PhoneNumberValidator do
  @moduledoc """
  Validate a phone number.

  This validator uses libphonenumber under the hood to
  validate phone numbers.

  This validator expects a `:country` argument to be passed
  so it can check the number corresponds to the given country.

  If you pass it `""` or `nil` it won't complain as long as the number
  is a valid E164 format that can be parsed without the country info.

  ## Examples

      iex> types = %{phone_number: :string}
      iex> params = %{phone_number: "0610234567"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_phone_number(:phone_number, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{phone_number: "0610234567"}, errors: [], data: %{}, valid?: true>

      iex> types = %{phone_number: :string}
      iex> params = %{phone_number: "798765432L"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_phone_number(:phone_number, country: "ch")
      #Ecto.Changeset<action: nil, changes: %{phone_number: "798765432L"}, errors: [], data: %{}, valid?: true>

      # Country can be ignored in E164 formatted numbers
      iex> types = %{phone_number: :string}
      iex> params = %{phone_number: "+16502530000"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_phone_number(:phone_number)
      #Ecto.Changeset<action: nil, changes: %{phone_number: "+16502530000"}, errors: [], data: %{}, valid?: true>


      iex> types = %{phone_number: :string}
      iex> params = %{phone_number: "01 23 45 67 89"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_phone_number(:phone_number, country: nil)
      #Ecto.Changeset<action: nil, changes: %{phone_number: "01 23 45 67 89"}, errors: [phone_number: {\"is not a valid phone number\", [validation: :phone_number]}], data: %{}, valid?: false>
  """

  import Ecto.Changeset

  def validate_phone_number(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:phone_number, opts}, fn _, value ->
      country_isoalpha2 = Keyword.get(opts, :country) || ""
      country_isoalpha2 = String.upcase(country_isoalpha2)

      with {:ok, parsed} <- ExPhoneNumber.parse(value, country_isoalpha2),
           true <- ExPhoneNumber.is_valid_number?(parsed) do
        []
      else
        _err ->
          [{field, {message(opts, "is not a valid phone number"), [validation: :phone_number]}}]
      end
    end)
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
