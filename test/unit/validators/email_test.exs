defmodule EctoCommons.EmailValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.EmailValidator, import: true
  alias EctoCommons.EmailValidator

  test "validate_email/2 default validator is [:html_input]" do
    assert chgst_helper("john.smith(comment)@example.com").valid? == false
    assert chgst_helper("john.smith(comment)@example.com", checks: [:pow]).valid? == true
  end

  test "validate_email/2 with :html_validator check" do
    # Local-part and domain from https://en.wikipedia.org/wiki/Email_address#Syntax
    # The default validator doesn't manage avanced use cases like
    # quotes or parenthesis
    assert chgst_helper("John..Doe@example.com").valid? == true
    assert chgst_helper("\"John..Doe\"@example.com").valid? == false
    assert chgst_helper("\".John.Doe\"@example.com").valid? == false
    assert chgst_helper("\"John.Doe.\"@example.com").valid? == false
    assert chgst_helper("john.smith(comment)@example.com").valid? == false
    assert chgst_helper("(comment)john.smith@example.com").valid? == false
    assert chgst_helper("john.smith@(comment)example.com").valid? == false
    assert chgst_helper("john.smith@example.com(comment)").valid? == false

    # Examples from https://en.wikipedia.org/wiki/Email_address#Examples
    # Common examples should work except quotes
    assert chgst_helper("simple@example.com").valid? == true
    assert chgst_helper("very.common@example.com").valid? == true
    assert chgst_helper("disposable.email.with+symbol@example.com").valid? == true
    assert chgst_helper("other.email-with-hyphen@example.com").valid? == true
    assert chgst_helper("fully-qualified-domain@example.com").valid? == true
    assert chgst_helper("user.name+tag+sorting@example.com").valid? == true
    assert chgst_helper("x@example.com").valid? == true
    assert chgst_helper("example-indeed@strange-example.com").valid? == true
    assert chgst_helper("admin@mailserver1").valid? == true
    assert chgst_helper("example@s.example").valid? == true
    assert chgst_helper("\" \"@example.org").valid? == false
    assert chgst_helper("\"john..doe\"@example.org").valid? == false
    assert chgst_helper("mailhost!username@example.org").valid? == true
    assert chgst_helper("user%example.com@example.org").valid? == true

    # Invalid examples from Wikipedia
    # Most invalid emails are catched by the simple regex used
    # by the default validator
    assert chgst_helper("Abc.example.com").valid? == false
    assert chgst_helper("A@b@c@example.com").valid? == false
    assert chgst_helper("a\"b(c)d,e:f;g<h>i[j\\k]l@example.com").valid? == false
    assert chgst_helper("just\"not\"right@example.com").valid? == false
    assert chgst_helper("this is\"not\\allowed@example.com").valid? == false

    assert chgst_helper("this\\ still\\\"not\\\\allowed@example.com").valid? ==
             false

    # Not catched
    assert chgst_helper(
             "1234567890123456789012345678901234567890123456789012345678901234+x@example.com"
           ).valid? == true

    assert chgst_helper("i_like_underscore@but_not_allowed_in_this_part.example.com").valid? ==
             false

    # Unicode from https://en.wikipedia.org/wiki/Email_address#Internationalization_examples
    # The default validator doesn't manage UTF8 email local parts.
    assert chgst_helper("Pelé@example.com").valid? == false
    assert chgst_helper("δοκιμή@παράδειγμα.δοκιμή").valid? == false
    assert chgst_helper("我買@屋企.香港").valid? == false
    assert chgst_helper("二ノ宮@黒川.日本").valid? == false
    assert chgst_helper("медведь@с-балалайкой.рф").valid? == false
    assert chgst_helper("संपर्क@डाटामेल.भारत").valid? == false

    # Test cases from https://tools.ietf.org/html/rfc3696#section-3
    # Quote issues corrected with https://www.rfc-editor.org/errata/rfc3696
    # The default validator doesn't manage quotes correctly
    assert chgst_helper("\"Abc\\@def\"@example.com").valid? == false
    assert chgst_helper("\"Fred\\ Bloggs\"@example.com").valid? == false
    assert chgst_helper("\"Joe.\\\\Blow\"@example.com").valid? == false
    assert chgst_helper("\"Abc@def\"@example.com").valid? == false
    assert chgst_helper("\"Fred Bloggs\"@example.com").valid? == false
    assert chgst_helper("user+mailbox@example.com").valid? == true
    assert chgst_helper("customer/department=shipping@example.com").valid? == true
    assert chgst_helper("$A12345@example.com").valid? == true
    assert chgst_helper("!def!xyz%abc@example.com").valid? == true
    assert chgst_helper("_somename@example.com").valid? == true

    # IPs are not accepted by the default validator
    assert chgst_helper("jsmith@[192.168.2.1]").valid? == false
    assert chgst_helper("jsmith@[::1]").valid? == false
    assert chgst_helper("jsmith@[IPv6:2001:db8::1]").valid? == false

    # Other successs cases
    assert chgst_helper(
             "john.doe@#{String.duplicate("x", 63)}.#{String.duplicate("x", 63)}.#{
               String.duplicate("x", 63)
             }.#{String.duplicate("x", 63)}"
           ).valid? == true

    assert chgst_helper("john.doe@1.2.com").valid? == true
    assert chgst_helper("john.doe@example.x1").valid? == true

    assert chgst_helper("john.doe@sub-domain-with-hyphen.domain-with-hyphen.com").valid? ==
             true

    # Other error cases
    assert chgst_helper("noatsign").valid? == false

    # The too-long domain is not captured either
    assert chgst_helper(
             "john.doe@#{String.duplicate("x", 63)}.#{String.duplicate("x", 63)}.#{
               String.duplicate("x", 63)
             }.#{String.duplicate("x", 60)}.com"
           ).valid? == true

    assert chgst_helper("john.doe@-example.com").valid? == false
    assert chgst_helper("john.doe@-example.example.com").valid? == false
    assert chgst_helper("john.doe@example-.com").valid? == false
    assert chgst_helper("john.doe@example-.example.com").valid? == false
    assert chgst_helper("john.doe@invaliddomain$").valid? == false
    assert chgst_helper("john(comment)doe@example.com").valid? == false
    assert chgst_helper("johndoe@example(comment).com").valid? == false
    assert chgst_helper("john.doe@.").valid? == false
    assert chgst_helper("john.doe@.com").valid? == false
    assert chgst_helper("john.doe@example.").valid? == false
    # This domain looks valid for the :html_validator
    assert chgst_helper("john.doe@example.1").valid? == true

    assert chgst_helper("john.doe@#{String.duplicate("x", 64)}.com").valid? ==
             false

    assert chgst_helper("john.doe@#{String.duplicate("x", 64)}.example.com").valid? ==
             false
  end

  test "validate_email/2 with :pow check" do
    # Local-part and domain from https://en.wikipedia.org/wiki/Email_address#Syntax
    assert chgst_helper("John..Doe@example.com", checks: [:pow]).valid? == false
    assert chgst_helper("\"John..Doe\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\".John.Doe\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\"John.Doe.\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("john.smith(comment)@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("(comment)john.smith@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("john.smith@(comment)example.com", checks: [:pow]).valid? == true
    assert chgst_helper("john.smith@example.com(comment)", checks: [:pow]).valid? == true

    # Examples from https://en.wikipedia.org/wiki/Email_address#Examples
    assert chgst_helper("simple@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("very.common@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("disposable.email.with+symbol@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("other.email-with-hyphen@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("fully-qualified-domain@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("user.name+tag+sorting@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("x@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("example-indeed@strange-example.com", checks: [:pow]).valid? == true
    assert chgst_helper("admin@mailserver1", checks: [:pow]).valid? == true
    assert chgst_helper("example@s.example", checks: [:pow]).valid? == true
    assert chgst_helper("\" \"@example.org", checks: [:pow]).valid? == true
    assert chgst_helper("\"john..doe\"@example.org", checks: [:pow]).valid? == true
    assert chgst_helper("mailhost!username@example.org", checks: [:pow]).valid? == true
    assert chgst_helper("user%example.com@example.org", checks: [:pow]).valid? == true

    # Invalid examples from Wikipedia
    assert chgst_helper("Abc.example.com", checks: [:pow]).valid? == false
    assert chgst_helper("A@b@c@example.com", checks: [:pow]).valid? == false
    assert chgst_helper("a\"b(c)d,e:f;g<h>i[j\\k]l@example.com", checks: [:pow]).valid? == false
    assert chgst_helper("just\"not\"right@example.com", checks: [:pow]).valid? == false
    assert chgst_helper("this is\"not\\allowed@example.com", checks: [:pow]).valid? == false

    assert chgst_helper("this\\ still\\\"not\\\\allowed@example.com", checks: [:pow]).valid? ==
             false

    assert chgst_helper(
             "1234567890123456789012345678901234567890123456789012345678901234+x@example.com",
             checks: [:pow]
           ).valid? == false

    assert chgst_helper("i_like_underscore@but_not_allowed_in_this_part.example.com",
             checks: [:pow]
           ).valid? ==
             false

    # Unicode from https://en.wikipedia.org/wiki/Email_address#Internationalization_examples
    assert chgst_helper("Pelé@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("δοκιμή@παράδειγμα.δοκιμή", checks: [:pow]).valid? == true
    assert chgst_helper("我買@屋企.香港", checks: [:pow]).valid? == true
    assert chgst_helper("二ノ宮@黒川.日本", checks: [:pow]).valid? == true
    assert chgst_helper("медведь@с-балалайкой.рф", checks: [:pow]).valid? == true
    assert chgst_helper("संपर्क@डाटामेल.भारत", checks: [:pow]).valid? == true

    # Test cases from https://tools.ietf.org/html/rfc3696#section-3
    # Quote issues corrected with https://www.rfc-editor.org/errata/rfc3696
    assert chgst_helper("\"Abc\\@def\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\"Fred\\ Bloggs\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\"Joe.\\\\Blow\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\"Abc@def\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("\"Fred Bloggs\"@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("user+mailbox@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("customer/department=shipping@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("$A12345@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("!def!xyz%abc@example.com", checks: [:pow]).valid? == true
    assert chgst_helper("_somename@example.com", checks: [:pow]).valid? == true

    # IPs not allowed
    assert chgst_helper("jsmith@[192.168.2.1]", checks: [:pow]).valid? == false
    assert chgst_helper("jsmith@[::1]", checks: [:pow]).valid? == false
    assert chgst_helper("jsmith@[IPv6:2001:db8::1]", checks: [:pow]).valid? == false

    # Other successs cases
    assert chgst_helper(
             "john.doe@#{String.duplicate("x", 63)}.#{String.duplicate("x", 63)}.#{
               String.duplicate("x", 63)
             }.#{String.duplicate("x", 63)}",
             checks: [:pow]
           ).valid? == true

    assert chgst_helper("john.doe@1.2.com", checks: [:pow]).valid? == true
    assert chgst_helper("john.doe@example.x1", checks: [:pow]).valid? == true

    assert chgst_helper("john.doe@sub-domain-with-hyphen.domain-with-hyphen.com", checks: [:pow]).valid? ==
             true

    # Other error cases
    assert chgst_helper("noatsign", checks: [:pow]).valid? == false

    assert chgst_helper(
             "john.doe@#{String.duplicate("x", 63)}.#{String.duplicate("x", 63)}.#{
               String.duplicate("x", 63)
             }.#{String.duplicate("x", 60)}.com",
             checks: [:pow]
           ).valid? == false

    assert chgst_helper("john.doe@-example.com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@-example.example.com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@example-.com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@example-.example.com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@invaliddomain$", checks: [:pow]).valid? == false
    assert chgst_helper("john(comment)doe@example.com", checks: [:pow]).valid? == false
    assert chgst_helper("johndoe@example(comment).com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@.", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@.com", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@example.", checks: [:pow]).valid? == false
    assert chgst_helper("john.doe@example.1", checks: [:pow]).valid? == false

    assert chgst_helper("john.doe@#{String.duplicate("x", 64)}.com", checks: [:pow]).valid? ==
             false

    assert chgst_helper("john.doe@#{String.duplicate("x", 64)}.example.com", checks: [:pow]).valid? ==
             false
  end

  defp chgst_helper(email, opts \\ []) do
    types = %{email: :string}
    params = %{email: email}

    Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
    |> EmailValidator.validate_email(:email, opts)
  end
end
