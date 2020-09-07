defmodule EctoCommons.SocialSecurityValidator do
  @moduledoc """
  This ecto validator checks the provided value is a
  valid social security number for a given country

  ## Example:

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "188037424305025"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_social_security(:admin_id, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{admin_id: "188037424305025"}, errors: [], data: %{}, valid?: true>

      # Also works for temporary french social security numbers and special edge cases (corsica)
      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "7 56 50 2B 233 042 82"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_social_security(:admin_id, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{admin_id: "7 56 50 2B 233 042 82"}, errors: [], data: %{}, valid?: true>

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "8 12 50 97 307 437 59"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_social_security(:admin_id, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{admin_id: "8 12 50 97 307 437 59"}, errors: [], data: %{}, valid?: true>

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "1 88 03 74 243 050 57"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_social_security(:admin_id, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{admin_id: "1 88 03 74 243 050 57"}, errors: [admin_id: {"is not a valid social security number", [validation: :social_security]}], data: %{}, valid?: false>

      iex> types = %{admin_id: :string}
      iex> params = %{admin_id: "this is an incorrect value"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_social_security(:admin_id, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{admin_id: "this is an incorrect value"}, errors: [admin_id: {"is not a valid social security number", [validation: :social_security]}], data: %{}, valid?: false>
  """
  import Ecto.Changeset

  # TODO: The France regex could be improved by using number ranges for the months and/or departments but
  # it's probably overkill for this validator.
  @france_regex ~r/^([123478][0-9]{2}[0-9]{2}(2[AB]|[0-9]{2})[0-9]{3}[0-9]{3})([0-9]{2})$/

  def validate_social_security(changeset, field, opts \\ []) do
    country =
      Keyword.get(opts, :country) || raise "No country specified for validate_social_security"

    validate_change(changeset, field, {:social_security, opts}, fn _, value ->
      value =
        String.upcase(value)
        |> String.split("", trim: true)
        |> Enum.filter(fn char -> String.match?(char, ~r/[0-9AB]/) end)
        |> Enum.join("")

      try do
        case valid?(value, country) do
          false ->
            [
              {field,
               {message(opts, "is not a valid social security number"),
                [validation: :social_security]}}
            ]

          true ->
            []
        end
      rescue
        _e ->
          [
            {field,
             {message(opts, "is not a valid social security number"),
              [validation: :social_security]}}
          ]
      end
    end)
  end

  @spec valid?(number :: integer | String.t(), country_isoalpha2 :: String.t()) :: boolean
  def valid?(number, country_isoalpha2) do
    case split_checksum(number, country_isoalpha2) do
      nil -> false
      {value, checkint} -> checksum(value, country_isoalpha2) == checkint
    end
  end

  def split_checksum(number, country_isoalpha2)

  def split_checksum(number, "fr") when is_binary(number) do
    case Regex.run(@france_regex, number) do
      nil ->
        nil

      [_regex, value, dept, check] ->
        value =
          case dept do
            "2A" -> String.replace(value, dept, "19")
            "2B" -> String.replace(value, dept, "18")
            _other -> value
          end

        {value, String.to_integer(check)}
    end
  end

  @spec checksum(binary, String.t()) :: integer
  def checksum(number, country_isoalpha2) when is_binary(number) do
    number
    |> String.to_integer()
    |> checksum(country_isoalpha2)
  end

  @spec checksum(integer, String.t()) :: integer
  def checksum(number, "fr") when is_integer(number), do: 97 - rem(number, 97)

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
