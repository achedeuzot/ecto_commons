defmodule EctoCommons.EmailValidator do
  @moduledoc ~S"""
  This validator is used to validate emails.

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
      ...> |> validate_email(:email, reject_burner_providers: true)
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [email: {"uses a forbidden provider", [validation: :email]}], data: %{}, valid?: false>

      iex> types = %{email: :string}
      iex> params = %{email: "uses_a_forbidden_provider@yopmail.net"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email, reject_burner_providers: false)
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [], data: %{}, valid?: true>

  """

  import Ecto.Changeset

  # We use the regular expression of the html `email` field specification.
  # See https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

  def validate_email(changeset, field, opts \\ []) do
    validate_change(changeset, field, {:email, opts}, fn _, value ->
      case Regex.match?(@email_regex, value) do
        true ->
          check_for_burners(value, field, opts)

        false ->
          [{field, {message(opts, "is not a valid email"), [validation: :email]}}]
      end
    end)
  end

  defp check_for_burners(value, field, opts) do
    if Keyword.get(opts, :reject_burner_providers, false) do
      case Burnex.is_burner?(value) do
        true ->
          [{field, {message(opts, "uses a forbidden provider"), [validation: :email]}}]

        false ->
          []
      end
    else
      []
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
