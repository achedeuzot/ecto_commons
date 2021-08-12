# Changelog

## Upcoming

## Version 0.3.3
- Bumped deps to latest versions
- Fixed regexes for some european countries in `PostalCodeValidator`

## Version 0.3.2
- Fixed documentation for `LuhnValidator`: adds example
  and documentation for `:transformer` optional function

## Version 0.3.1
- `validate_email`: Adds email MX check with `:check_mx_record` validator.
- Bumped dependencies, including credo and burnex.
- Added some tests on `TimeValidator`, `DateValidator` and `DateTimeValidator`.
- Adds a `:transformer` func optional argumet to `LuhnValidator` if you
  need to change the value before validation without modifying the
  changeset. It's useful if the number contains letters that must
  be converted to digits before checking the Luhn validity.
- Fixed `SocialSecurityValidator` by using a less strict character filter.

## Version 0.3.0
- Ecto Validators:
  - `validate_email`: Fix default checks to `:html_input` instead of `:pow` and
     adds tests to confirm this is always the case to match documentation
  - `validate_email`: Update `:pow` validation with upstream changes
  - `validate_phone_number`: Validate phone numbers using libphonenumber
- Misc:
  - moved from Travis CI to GitHub Actions

## Version 0.2.0
- Ecto Validators:
  - `validate_email`: Improved email validation options and better documentation
    about what to expect.
  - `validate_url`: Improved documentation about what is supported.
  - `validate_postal_code`: Added support for all countries. Still only a sanity
     check. There is no full databases of all postal codes packages into this lib ;)
- Ecto Helpers:
  - `validate_many`: adds validation for multiple fields with the same
    validation function.

## Version 0.1.0
 - Ecto Validators:
   - `validate_date`: validates `Date` (equality, after, before)
   - `validate_datetime`: validates `DateTime` (equality, after, before)
   - `validate_time`: validates `Time` (equality, after, before)
   - `validate_email`: validates emails (and can also prevent temporary email
     providers by using `Burnex` package)
   - `validate_luhn`: validates codes that respect the Luhn algorithm such
     as credit cards
   - `validate_url`: validates URLs with various criteria
   - `validate_string`: validates strings with a given prefix
   - `validate_postal_code`: validates postal codes for a few european countries
   - `validate_social_security`: validates social security numbers for French
     administration
