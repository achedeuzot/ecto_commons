defmodule EctoCommons.EmailValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.EmailValidator, import: true
  alias EctoCommons.EmailValidator

  @valid_emails [
    "simple@example.com",
    "very.common@example.com",
    "disposable.style.email.with+symbol@example.com",
    "other.email-with-hyphen@example.com",
    "fully-qualified-domain@example.com",
    "user.name+tag+sorting@example.co",
    "x@example.com",
    "example-indeed@strange-example.com",
    "admin@mailserver1",
    "example@s.example",
    "\" \"@example.org",
    "\"john..doe\"@example.org",
    "mailhost!username@example.org",
    "user%example.com@example.org",
    # IPv4 and IPv6
    "user.name@192.168.0.1",
    "user.name@[::1]",
    "user.name@[2001:db8:a0b:12f0::1]",
    "user.name@[2001:0db8:0000:0000:0000:0000:18.52.86.120]",
    # Unicode
    "Pelé@example.com",
    "δοκιμή@παράδειγμα.δοκιμή",
    "我買@屋企.香港",
    "二ノ宮@黒川.日本",
    "медведь@с-балалайкой.рф"
    # "संपर्क@डाटामेल.भारत" Unfortunately, this doesn't work :/
  ]
  @invalid_emails [
    "Abc.example.com",
    "A@b@c@example.com",
    "a\"b(c)d,e:f;g<h>i[j\k]l@example.com",
    "just\"not\"right@example.com",
    "this is\"not\\allowed@example.com",
    "this\\ still\\\"not\\\\allowed@example.com",
    "1234567890123456789012345678901234567890123456789012345678901234+x@example.com",
    "i_like_underscore@but_its_not_allow_in_this_part.example.com",
    "some.user@.example.",
    "john..doe@example.com",
    # "john.doe@#{String.duplicate("x", 256)}", this doesn't work with the test name interpolation: SystemLimitError
    "john.doe@-example.com",
    "john.doe@example-",
    "john.doe@invaliddomain$"
  ]

  for email <- @valid_emails do
    test "valid email: #{email}" do
      types = %{email: :string}
      params = %{email: unquote(email)}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> EmailValidator.validate_email(:email)

      assert result.valid? == true
    end
  end

  for email <- @invalid_emails do
    test "invalid email: #{email}" do
      types = %{email: :string}
      params = %{email: unquote(email)}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> EmailValidator.validate_email(:email)

      assert result.valid? == false
    end
  end
end
