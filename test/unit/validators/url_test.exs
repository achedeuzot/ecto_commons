defmodule EctoCommons.URLValidatorTest do
  use ExUnit.Case, async: true

  doctest EctoCommons.URLValidator, import: true
  alias EctoCommons.URLValidator

  @valid_urls [
    # Default checks
    {"https://user:password@www.example.com/path/part?query=param&other=param#frags", []},
    {"http://foo.com/blah_blah", []},
    {"http://foo.com/blah_blah/", []},
    {"http://foo.com/blah_blah_(wikipedia)", []},
    {"http://foo.com/blah_blah_(wikipedia)_(again)", []},
    {"http://www.example.com/wpstyle/?p=364", []},
    {"https://www.example.com/foo/?bar=baz&inga=42&quux", []},
    {"http://userid:password@example.com:8080", []},
    {"http://userid:password@example.com:8080/", []},
    {"http://userid@example.com", []},
    {"http://userid@example.com/", []},
    {"http://userid@example.com:8080", []},
    {"http://userid@example.com:8080/", []},
    {"http://userid:password@example.com", []},
    {"http://userid:password@example.com/", []},
    {"http://142.42.1.1/", []},
    {"http://142.42.1.1:8080/", []},
    {"http://foo.com/blah_(wikipedia)#cite-1", []},
    {"http://foo.com/blah_(wikipedia)_blah#cite-1", []},
    {"http://foo.com/(something)?after=parens", []},
    {"http://code.google.com/events/#&product=browser", []},
    {"http://j.mp", []},
    {"ftp://foo.bar/baz", []},
    {"ftps://foo.bar/", []},
    {"http://foo.bar/?q=Test%20URL-encoded%20stuff", []},
    {"http://-.~_!$&()*+,;=:%40:80%2f::::::@example.com", []},
    {"http://1337.net", []},
    {"http://a.b-c.de", []},
    {"http://223.255.255.254", []},
    {"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html", []},
    {"http://[1080:0:0:0:8:800:200C:417A]/index.html", []},
    {"http://[3ffe:2a00:100:7031::1]", []},
    {"http://[1080::8:800:200C:417A]/foo", []},
    {"http://[::192.9.5.5]/ipng", []},
    {"http://[::FFFF:129.144.52.38]:80/index.html", []},
    {"http://[2010:836B:4179::836B:4179]", []},

    # Checks without `:parsable` because of UTF8 symbols
    {"http://✪df.ws/123", [checks: [:empty, :scheme, :host]]},
    {"http://➡.ws/䨹", [checks: [:empty, :scheme, :host]]},
    {"http://⌘.ws", [checks: [:empty, :scheme, :host]]},
    {"http://⌘.ws/", [checks: [:empty, :scheme, :host]]},
    {"http://foo.com/unicode_(✪)_in_parens", [checks: [:empty, :scheme, :host]]},
    {"http://☺.damowmow.com/", [checks: [:empty, :scheme, :host]]},
    {"http://مثال.إختبار", [checks: [:empty, :scheme, :host]]},
    {"http://例子.测试", [checks: [:empty, :scheme, :host]]},
    {"http://उदाहरण.परीक्षा", [checks: [:empty, :scheme, :host]]},

    # Check host exists
    {"http://github.com/", [checks: [:parsable, :empty, :scheme, :host, :valid_host]]}
  ]

  @invalid_urls [
    # Default checks
    {"some random string", []},
    {"http//:example.com", []},
    {"//", []},
    {"//a", []},
    {"///a", []},
    {"///", []},
    {"http://", []},
    {"http:///a", []},
    {"foo.com", []},
    {":// should fail", []},
    {"://", []},

    # Add additional check with http_regexp
    {"http://.", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://..", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://../", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://?", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://??", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://??/", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://#", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://##", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://##/", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://foo.bar?q=Spaces should be encoded",
     [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http:// shouldfail.com", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://foo.bar/foo(bar)baz quux",
     [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://a.b--c.de/", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://-a.b.co", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://a.b-.co", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://.www.foo.bar/", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://www.foo.bar./", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://.www.foo.bar./", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://-error-.invalid/", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    # Invalid IPs catched by http_regexp
    {"http://0.0.0.0", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://10.1.1.0", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://10.1.1.255", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://224.1.1.1", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://1.1.1.1.1", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://123.123.123", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://3628126748", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://10.1.1.1", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},
    {"http://10.1.1.254", [checks: [:parsable, :empty, :scheme, :host, :http_regexp]]},

    # Add host checking (does an HTTP request)
    {"http://completely-unknown.example.com/",
     [checks: [:parsable, :empty, :scheme, :host, :valid_host]]}
  ]

  for {url, opts} <- @valid_urls do
    test "valid url: #{url}" do
      types = %{url: :string}
      params = %{url: unquote(url)}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> URLValidator.validate_url(:url, unquote(opts))

      assert result.valid?
    end
  end

  for {url, opts} <- @invalid_urls do
    test "invalid url: #{url}" do
      types = %{url: :string}
      params = %{url: unquote(url)}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> URLValidator.validate_url(:url, unquote(opts))

      refute result.valid?
    end
  end
end
