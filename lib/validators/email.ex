defmodule EctoCommons.EmailValidator do
  @moduledoc ~S"""
  Validates emails.

  ## Options
  There are various `:checks` depending on the strictness of the validation you require. Indeed, perfect email validation
  does not exist (see StackOverflow questions about it):

  - `:html_input`: Checks if the email follows the regular expression used by browsers for
    their `type="email"` input fields. This is the default as it corresponds to most use-cases. It is quite strict
    without being too narrow. It does not support unicode emails though. If you need better internationalization,
    please use the `:pow` check as it is more flexible with international emails. Defaults to enabled.
  - `:burner`: Checks if the email given is a burner email provider (uses the `Burnex` lib under the hood).
    When enabled, will reject temporary email providers. Defaults to disabled.
  - `:pow`: Checks the email using the [`pow`](https://hex.pm/packages/pow) logic. Defaults to disabled.
    The rules are the following:
    - Split into local-part and domain at last `@` occurrence
    - Local-part should;
      - be at most 64 octets
      - separate quoted and unquoted content with a single dot
      - only have letters, digits, and the following characters outside quoted
        content:
          ```text
          !#$%&'*+-/=?^_`{|}~.
          ```
      - not have any consecutive dots outside quoted content
    - Domain should;
      - be at most 255 octets
      - only have letters, digits, hyphen, and dots

    Unicode characters are permitted in both local-part and domain.

    The implementation is based on [RFC 3696](https://tools.ietf.org/html/rfc3696#section-3).
    IP addresses are not allowed as per the RFC 3696 specification: "The domain name can also be
    replaced by an IP address in square brackets, but that form is strongly discouraged except
    for testing and troubleshooting purposes.".

    You're invited to compare the tests to see the difference between the `:html_input`
    check and the `:pow` check. `:pow` is better suited for i18n and is more correct
    in regards to the email specification but will allow valid emails many systems don't
    manage correctly. `:html_input` is more basic but should be OK for most common use-cases.

  ## Example:

      iex> types = %{email: :string}
      iex> params = %{email: "valid.email@example.com"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email)
      #Ecto.Changeset<action: nil, changes: %{email: "valid.email@example.com"}, errors: [], data: %{}, valid?: true>

      iex> types = %{email: :string}
      iex> params = %{email: "@invalid_email"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email)
      #Ecto.Changeset<action: nil, changes: %{email: "@invalid_email"}, errors: [email: {"is not a valid email", [validation: :email]}], data: %{}, valid?: false>

      iex> types = %{email: :string}
      iex> params = %{email: "uses_a_forbidden_provider@yopmail.net"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email, checks: [:html_input, :burner])
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [email: {"uses a forbidden provider", [validation: :email]}], data: %{}, valid?: false>

      iex> types = %{email: :string}
      iex> params = %{email: "uses_a_forbidden_provider@yopmail.net"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email, checks: [:html_input, :pow])
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [], data: %{}, valid?: true>

  """

  import Ecto.Changeset

  # We use the regular expression of the html `email` field specification.
  # See https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)
  # and https://stackoverflow.com/a/15659649/1656568
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

  def validate_email(%Ecto.Changeset{} = changeset, field, opts \\ []) do
    validate_change(changeset, field, {:email, opts}, fn _, value ->
      checks = Keyword.get(opts, :checks, [:html_input])

      # credo:disable-for-lines:6 Credo.Check.Refactor.Nesting
      Enum.reduce(checks, [], fn check, errors ->
        case do_validate_email(value, check) do
          :ok -> errors
          {:error, msg} -> [{field, {message(opts, msg), [validation: :email]}} | errors]
        end
      end)
      |> List.flatten()
    end)
  end

  @spec do_validate_email(String.t(), atom()) :: :ok | {:error, String.t()}
  defp do_validate_email(email, :burner) do
    if Burnex.is_burner?(email) do
      {:error, "uses a forbidden provider"}
    else
      :ok
    end
  end

  defp do_validate_email(email, :html_input) do
    if String.match?(email, @email_regex),
      do: :ok,
      else: {:error, "is not a valid email"}
  end

  defp do_validate_email(email, :pow) do
    case pow_validate_email(email) do
      :ok -> :ok
      {:error, _msg} -> {:error, "is not a valid email"}
    end
  end

  # The code below is copied and adapted from the [pow](https://hex.pm/packages/pow) package
  # We just don't want to import the whole `pow` package as a dependency.
  defp pow_validate_email(email) do
    [domain | local_parts] =
      email
      |> String.split("@")
      |> Enum.reverse()

    local_part =
      local_parts
      |> Enum.reverse()
      |> Enum.join("@")

    cond do
      String.length(local_part) > 64 -> {:error, "local-part too long"}
      String.length(domain) > 255 -> {:error, "domain too long"}
      local_part == "" -> {:error, "invalid format"}
      local_part_only_quoted?(local_part) -> validate_domain(domain)
      true -> pow_validate_email(local_part, domain)
    end
  end

  defp pow_validate_email(local_part, domain) do
    sanitized_local_part =
      local_part
      |> remove_comments()
      |> remove_quotes_from_local_part()

    cond do
      local_part_consective_dots?(sanitized_local_part) ->
        {:error, "consective dots in local-part"}

      local_part_valid_characters?(sanitized_local_part) ->
        validate_domain(domain)

      true ->
        {:error, "invalid characters in local-part"}
    end
  end

  defp local_part_only_quoted?(local_part),
    do: local_part =~ ~r/^"[^\"]+"$/

  defp remove_quotes_from_local_part(local_part),
    do: Regex.replace(~r/(^\".*\"$)|(^\".*\"\.)|(\.\".*\"$)?/, local_part, "")

  defp remove_comments(any),
    do: Regex.replace(~r/(^\(.*\))|(\(.*\)$)?/, any, "")

  defp local_part_consective_dots?(local_part),
    do: local_part =~ ~r/\.\./

  defp local_part_valid_characters?(sanitized_local_part),
    do: sanitized_local_part =~ ~r<^[\p{L}\p{M}0-9!#$%&'*+-/=?^_`{|}~\.]+$>u

  defp validate_domain(domain) do
    sanitized_domain = remove_comments(domain)

    labels =
      sanitized_domain
      |> remove_comments()
      |> String.split(".")

    labels
    |> validate_tld()
    |> validate_dns_labels()
  end

  defp validate_tld(labels) do
    labels
    |> List.last()
    |> Kernel.=~(~r/^[0-9]+$/)
    |> case do
      true -> {:error, "tld cannot be all-numeric"}
      false -> {:ok, labels}
    end
  end

  defp validate_dns_labels({:ok, labels}) do
    Enum.reduce_while(labels, :ok, fn
      label, :ok -> {:cont, validate_dns_label(label)}
      _label, error -> {:halt, error}
    end)
  end

  defp validate_dns_labels({:error, error}), do: {:error, error}

  defp validate_dns_label(label) do
    cond do
      label == "" -> {:error, "dns label is too short"}
      String.length(label) > 63 -> {:error, "dns label too long"}
      String.first(label) == "-" -> {:error, "dns label begins with hyphen"}
      String.last(label) == "-" -> {:error, "dns label ends with hyphen"}
      dns_label_valid_characters?(label) -> :ok
      true -> {:error, "invalid characters in dns label"}
    end
  end

  defp dns_label_valid_characters?(label),
    do: label =~ ~r/^[\p{L}\p{M}0-9-]+$/u

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
