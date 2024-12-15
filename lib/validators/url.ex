defmodule EctoCommons.URLValidator do
  @moduledoc ~S"""
  This validator is used to validate URLs.

  ## Options
  There are some available `:checks` depending on the strictness of what you want to validate:

    - `:parsable`: Checks to see if the URL is parsable by `:http_uri.parse/1` Erlang function.
       This can have issues with international URLs where it should be disabled (see tests). Defaults to enabled
    - `:empty`: Checks to see if the parsed `%URI{}` struct is not empty (all fields set to nil). Defaults to enabled
    - `:scheme`: Checks to see if the parsed `%URI{}` struct contains a `:scheme`. Defaults to enabled
    - `:host`: Checks to see if the parsed `%URI{}` struct contains a `:host`. Defaults to enabled
    - `:valid_host`: Does a `:inet.getbyhostname/1` call to check if the host exists. This will do a network call.
       Defaults to disabled
    - `:path`: Checks to see if the parsed `%URI{}` struct contains a `:path`. Defaults to disabled
    - `:http_regexp`: Tries to match URL to a regexp known to catch many unwanted URLs (see code). It only accepts
       HTTP(S) and FTP schemes though. Defaults to disabled

  The approach is not yet very satisfactory IMHO, if you have suggestions, Pull Requests are welcome :)

  ## Example:

      iex> types = %{url: :string}
      iex> params = %{url: "https://www.example.com/"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_url(:url)
      #Ecto.Changeset<action: nil, changes: %{url: "https://www.example.com/"}, errors: [], data: %{}, valid?: true>

      iex> types = %{url: :string}
      iex> params = %{url: "https://www.example.com/"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_url(:url, checks: [:empty, :path, :scheme, :host])
      #Ecto.Changeset<action: nil, changes: %{url: "https://www.example.com/"}, errors: [], data: %{}, valid?: true>

      iex> types = %{url: :string}
      iex> params = %{url: "some@invalid_url"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_url(:url)
      #Ecto.Changeset<action: nil, changes: %{url: "some@invalid_url"}, errors: [url: {"is not a valid url", [validation: :url]}], data: %{}, valid?: false>

      iex> types = %{url: :string}
      iex> params = %{url: "Just some random text"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_url(:url)
      #Ecto.Changeset<action: nil, changes: %{url: "Just some random text"}, errors: [url: {"is not a valid url", [validation: :url]}], data: %{}, valid?: false>

  """

  import Ecto.Changeset

  # Taken from here https://mathiasbynens.be/demo/url-regex
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @http_regex ~r/^(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?$/ius

  def validate_url(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:url, opts}, fn _, value ->
      checks = Keyword.get(opts, :checks, [:parsable, :empty, :scheme, :host])
      parsed = URI.parse(value)

      case do_validate_url(value, parsed, checks) do
        :ok -> []
        :error -> [{field, {message(opts, :message, "is not a valid url"), [validation: :url]}}]
      end
    end)
  end

  defp do_validate_url(value, parsed, checks) when is_list(checks) do
    check_all = Enum.map(checks, fn check -> do_validate_url(value, parsed, check) end)

    if Enum.member?(check_all, :error), do: :error, else: :ok
  end

  defp do_validate_url(value, _parsed, :parsable) do
    case URI.new(value) do
      {:ok, _uri} -> :ok
      {:error, _msg} -> :error
    end
  end

  defp do_validate_url(value, _parsed, :http_regexp) do
    case String.match?(value, @http_regex) do
      true -> :ok
      false -> :error
    end
  end

  # Caution: this check does a network call and can be slow.
  defp do_validate_url(_value, %URI{host: host}, :valid_host) do
    case :inet.gethostbyname(String.to_charlist(host)) do
      {:ok, _value} -> :ok
      {:error, :nxdomain} -> :error
    end
  end

  defp do_validate_url(_value, parsed, :empty) do
    values = parsed |> Map.from_struct() |> Enum.map(fn {_key, val} -> blank?(val) end)

    if Enum.member?(values, false), do: :ok, else: :error
  end

  defp do_validate_url(_value, %URI{path: path} = _parsed, :path) do
    if blank?(path), do: :error, else: :ok
  end

  defp do_validate_url(_value, %URI{scheme: scheme} = _parsed, :scheme) do
    if blank?(scheme), do: :error, else: :ok
  end

  defp do_validate_url(_value, %URI{host: host} = _parsed, :host) do
    if blank?(host), do: :error, else: :ok
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end

  @compile {:inline, blank?: 1}
  def blank?(""), do: true
  def blank?([]), do: true
  def blank?(nil), do: true
  def blank?({}), do: true
  def blank?(%{} = map) when map_size(map) == 0, do: true
  def blank?(_), do: false
end
