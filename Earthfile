VERSION 0.6

all:
    BUILD \
        --build-arg ELIXIR_BASE=1.13.0-erlang-22.3.4.2-alpine-3.12.0 \
        --build-arg ELIXIR_BASE=1.14.5-erlang-24.3.4.15-alpine-3.18.4 \
        --build-arg ELIXIR_BASE=1.16.0-erlang-26.2.1-alpine-3.17.5 \
        +test

test:
    ARG ELIXIR_BASE=1.9.4-erlang-20.3.8.26-alpine-3.11.6
    FROM hexpm/elixir:$ELIXIR_BASE
    RUN apk add --no-progress --update git build-base
    RUN mix local.rebar --force
    RUN mix local.hex --force
    WORKDIR /src/ecto_commons

    COPY mix.exs mix.lock .formatter.exs .dialyzer_ignore.exs ./
    RUN mix deps.get
    RUN MIX_ENV=test mix deps.compile

    COPY --dir lib priv test ./
    RUN mix compile --warnings-as-errors
    RUN mix dialyzer
    IF [ -n "$COVERALLS_GITHUB" ]
      RUN mix coveralls.github
    ELSE
      RUN mix test
    END
