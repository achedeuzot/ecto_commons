VERSION 0.6

all:
    BUILD \
        --build-arg ELIXIR_BASE=1.14.5-erlang-24.3.4.15-alpine-3.18.4 \
        --build-arg ELIXIR_BASE=1.15.7-erlang-26.2.5.17-alpine-3.21.6 \
        --build-arg ELIXIR_BASE=1.16.2-erlang-26.2.5.17-alpine-3.21.6 \
        --build-arg ELIXIR_BASE=1.17.3-erlang-26.2.5.17-alpine-3.21.6 \
        --build-arg ELIXIR_BASE=1.18.4-erlang-26.2.5.17-alpine-3.21.6 \
        --build-arg ELIXIR_BASE=1.19.5-erlang-26.2.5.17-alpine-3.21.6 \
        +test

test:
    ARG ELIXIR_BASE=1.14.5-erlang-24.3.4.15-alpine-3.18.4
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
