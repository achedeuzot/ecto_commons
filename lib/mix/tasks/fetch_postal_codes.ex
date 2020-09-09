defmodule Mix.Tasks.FetchPostalCodes do
  @moduledoc """
  This task fetches country data from http://i18napis.appspot.com/address

  It will only fetch first-level directories (countries)
  and write the country code followed by the postal code regular expression.
  For example: IT;\\d{5}
  """
  use Mix.Task

  alias EctoCommons.I18nAPIsClient

  @impl Mix.Task
  @shortdoc "Fetches country zip codes regex from i18napis.appspot.com"
  def run(_args) do
    Finch.start_link(name: EctoCommons.I18nAPIsClient)

    # Get all of the countries on the first level response
    {:ok, countries} = I18nAPIsClient.get_all_countries()

    # Concurrently process all of the countries and aggregate the results
    countries
    |> Task.async_stream(&I18nAPIsClient.get_country_info/1,
      max_concurrency: I18nAPIsClient.pool_size()
    )
    |> Enum.filter(fn {:ok, item} ->
      case item do
        {:ok, _, _} -> true
        :empty -> false
      end
    end)
    |> Enum.reduce([], fn {:ok, {:ok, key, zip}}, acc ->
      [{key, zip} | acc]
    end)
    |> print_table_results()
  end

  defp print_table_results(results) do
    results
    |> Enum.sort(fn {key_1, _zip_1}, {key_2, _zip_2} ->
      key_1 < key_2
    end)
    |> Enum.each(fn {country, regex} ->
      IO.puts("#{country};#{regex}")
    end)
  end
end
