defmodule EctoCommons.I18nAPIsClient do
  @moduledoc """
  This is a client for the http://i18napis.appspot.com/address website.

  It's used to fetch country information, mainly postal codes regular expressions
  used in the `EctoCommons.PostalCodeValidator`.
  """
  alias Finch.Response

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       "http://i18napis.appspot.com" => [size: pool_size()]
     }}
  end

  def pool_size, do: 10

  def get_all_countries do
    :get
    |> Finch.build("http://i18napis.appspot.com/address")
    |> Finch.request(__MODULE__)
    |> handle_countries_listing_response()
  end

  def get_country_info(country) do
    :get
    |> Finch.build("http://i18napis.appspot.com/address/data/#{country}")
    |> Finch.request(__MODULE__)
    |> handle_country_response()
  end

  defp handle_countries_listing_response({:ok, %Response{body: body}}) do
    countries =
      Regex.scan(~r/<a href='\/address\/data\/([A-Z]{2})'>/, body)
      |> Enum.map(fn [_url, country_code] -> country_code end)

    {:ok, countries}
  end

  defp handle_country_response({:ok, %Response{body: body}}) do
    body
    |> Jason.decode!()
    |> case do
      %{"key" => key, "zip" => zip} -> {:ok, key, zip}
      _ -> :empty
    end
  end
end
