defmodule EctoCommons.PostalCodeValidator do
  @moduledoc """
  Valide the postal code within a country context.

  For now, only a few countries are supported:
    - France
    - Belgium
    - Italy
    - Spain
    - Switzerland
    - United Kingdom

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

  # https://rgxdb.com/r/3B1KKRYC
  @fr_regexp ~r/^([0-8]\d|9[0-8])[ ]?\d{3}$/
  @be_regexp ~r/^(([1-9])(\d{3}))$/
  @it_regexp ~r/^\d{5}$/
  @es_regexp ~r/^(0[1-9]|[1-4]\d|5[0-2])\d{3}$/
  @ch_regexp ~r/^[1-9]\d{3}$/
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @gb_regexp ~r/^GIR[ ]?0AA|((AB|AL|B|BA|BB|BD|BH|BL|BN|BR|BS|BT|CA|CB|CF|CH|CM|CO|CR|CT|CV|CW|DA|DD|DE|DG|DH|DL|DN|DT|DY|E|EC|EH|EN|EX|FK|FY|G|GL|GY|GU|HA|HD|HG|HP|HR|HS|HU|HX|IG|IM|IP|IV|JE|KA|KT|KW|KY|L|LA|LD|LE|LL|LN|LS|LU|M|ME|MK|ML|N|NE|NG|NN|NP|NR|NW|OL|OX|PA|PE|PH|PL|PO|PR|RG|RH|RM|S|SA|SE|SG|SK|SL|SM|SN|SO|SP|SR|SS|ST|SW|SY|TA|TD|TF|TN|TQ|TR|TS|TW|UB|W|WA|WC|WD|WF|WN|WR|WS|WV|YO|ZE)(\d[\dA-Z]?[ ]?\d[ABD-HJLN-UW-Z]{2}))|BFPO[ ]?\d{1,4}$/

  def validate_postal_code(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:postal_code, opts}, fn _, value ->
      country_isoalpha2 =
        Keyword.get(opts, :country) || raise "No country specified for validate_postal_code"

      case String.match?(value, get_regexp(country_isoalpha2)) do
        true ->
          []

        false ->
          [{field, {message(opts, "is not a valid postal code"), [validation: :postal_code]}}]
      end
    end)
  end

  # TODO: Add more countries regexp to match common use. We could directly import a CSV
  # file containing country code + regexp to use
  defp get_regexp("fr"), do: @fr_regexp
  defp get_regexp("be"), do: @be_regexp
  defp get_regexp("ch"), do: @ch_regexp
  defp get_regexp("it"), do: @it_regexp
  defp get_regexp("es"), do: @es_regexp
  defp get_regexp("gb"), do: @gb_regexp

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
