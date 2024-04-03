defmodule EctoCommons.PostalCodeValidator do
  @moduledoc """
  Validate the postal code within a country context.

  This validator will only validate the postal code against known
  regex formats for a given country, it won't match the postal
  code to an actual database of all available postal codes in each country.

  ## Examples

      iex> types = %{postal_code: :string}
      iex> params = %{postal_code: "69001"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_postal_code(:postal_code, country: "fr")
      #Ecto.Changeset<action: nil, changes: %{postal_code: "69001"}, errors: [], data: %{}, valid?: true>

      iex> types = %{postal_code: :string}
      iex> params = %{postal_code: "1120"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_postal_code(:postal_code, country: "be")
      #Ecto.Changeset<action: nil, changes: %{postal_code: "1120"}, errors: [], data: %{}, valid?: true>

      iex> types = %{postal_code: :string}
      iex> params = %{postal_code: "00199"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_postal_code(:postal_code, country: "it")
      #Ecto.Changeset<action: nil, changes: %{postal_code: "00199"}, errors: [], data: %{}, valid?: true>

      iex> types = %{postal_code: :string}
      iex> params = %{postal_code: "28010"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_postal_code(:postal_code, country: "es")
      #Ecto.Changeset<action: nil, changes: %{postal_code: "28010"}, errors: [], data: %{}, valid?: true>

      iex> types = %{postal_code: :string}
      iex> params = %{postal_code: "1211"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_postal_code(:postal_code, country: "ch")
      #Ecto.Changeset<action: nil, changes: %{postal_code: "1211"}, errors: [], data: %{}, valid?: true>
  """

  import Ecto.Changeset

  # Postal codes were fetched once from http://i18napis.appspot.com/address
  # which is recommended by the Unicode folks. The unicode database of regexes for
  # countries was not maintained anymore. The following regexes were then
  # improved upon to be more restrictive: FR, IT, BE, ES
  @postal_codes_data Path.absname("priv/data/postal_codes.csv")
                     |> Path.absname()
                     |> File.read!()
                     |> String.split("\n", trim: true)

  def validate_postal_code(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:postal_code, opts}, fn _, value ->
      country_isoalpha2 =
        Keyword.get(opts, :country) || raise "No country specified for validate_postal_code"

      case String.match?(value, get_regexp(country_isoalpha2, opts)) do
        true ->
          []

        false ->
          [{field, {message(opts, "is not a valid postal code"), [validation: :postal_code]}}]
      end
    end)
  end

  @postal_codes_data
  |> Enum.each(fn country_data ->
    [isoalpha2, regex] = String.split(country_data, ";", parts: 2)
    argument = String.downcase(isoalpha2)
    {:ok, regex} = Regex.compile("^" <> regex <> "$")

    def get_regexp(unquote(argument), _opts), do: unquote(Macro.escape(regex))
  end)

  def get_regexp(_unknown, opts) do
    if Keyword.get(opts, :raise_if_unknown_country, false) do
      raise ArgumentError, "Unknown country code for validate_postal_code"
    end

    if Keyword.get(opts, :reject_if_unknown_country, false) do
      ~r/^(?!x)x/ # Can't match anything
    else
      ~r/.*/ # Accept all postal codes
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
