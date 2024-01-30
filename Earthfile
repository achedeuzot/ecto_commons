VERSION 0.6

all:
    BUILD \
        --build-arg ELIXIR_BASE=1.9.4-erlang-20.3.8.26-alpine-3.11.6 \
        --build-arg ELIXIR_BASE=1.11.3-erlang-23.2.7.5-alpine-3.16.0 \
        +test

test:
    ARG ELIXIR_BASE=1.9.4-erlang-20.3.8.26-alpine-3.11.6
    FROM hexpm/elixir:$ELIXIR_BASE
    RUN apk add --no-progress --update git build-base
    RUN mix local.rebar --force
    RUN mix local.hex --force
    WORKDIR /src/ecto_commons

    COPY mix.exs mix.lock .formatter.exs ./
    RUN mix deps.get
    RUN MIX_ENV=test mix deps.compile

    COPY --dir lib priv test ./
    RUN mix test
