# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20210902-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.13.3-erlang-25.0.3-debian-bullseye-20210902-slim
#

ARG APP_NAME=framework
ARG ORGANIZATION="hexpm/elixir"

ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=27.2
ARG OS=debian
ARG OS_VERSION=bullseye
ARG OS_RELEASE="20241202-slim"
ARG BUILDER_IMAGE="${ORGANIZATION}:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-${OS}-${OS_VERSION}-${OS_RELEASE}"
ARG RUNNER_IMAGE="${OS}:${OS_VERSION}-${OS_RELEASE}"
ARG RUST_VERSION=1.81


#FROM rust:${RUST_VERSION} as martin_builder
#WORKDIR /usr/src/martin
#COPY . .
#RUN cargo install cargo-binstall && cargo binstall martin --no-confirm


FROM ${BUILDER_IMAGE} as builder
ENV TZ=US \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
     apt-get install -y \
             build-essential \
             git \
             npm  \
             libvips-dev  \
             webp esbuild && \
     apt-get clean && \
     rm -f /var/lib/apt/lists/*_*

WORKDIR "/app"
# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

# Install / update  JavaScript dependencies
#RUN npm install --prefix ./assets

COPY assets assets

# Compile the release
RUN mix compile
# compile assets
RUN mix assets.deploy


# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}
ENV TZ=US \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y python3.12 iputils tini curl nano tzdata bash libstdc++6 curl gifsicle libcairo2 libjpeg-turbo-progs openssl libncurses5 locales webp git libvips-dev npm\
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV TERM="xterm-256color" \
TIME_STYLE="long-iso"

ENV PYTHONUNBUFFERED=1 \
PYTHONDONTWRITEBYTECODE=1

# Enable jpegtran optimizer https://thumbor.readthedocs.io/en/latest/jpegtran.html#jpegtran
ENV OPTIMIZERS="['thumbor.optimizers.jpegtran']"

RUN set -eux \
    && apk add --quiet --no-cache --virtual .build-deps \
    # thumbor requirements:
    curl-dev g++ \
    # Thumbor
    && pip install --quiet --no-cache-dir --upgrade pip \
    && pip install --quiet --no-cache-dir \
        # Jinja2 and envtpl are required to work with environtment variables
        Jinja2==3.1.* envtpl==0.7.* \
        # sentry is required for error tracking
        "sentry-sdk==1.*,>=1.39.1" \
        # numpy - https://github.com/beeyev/thumbor-s3-docker/pull/14
        "numpy==1.*,>=1.26.3" \
        # pycurl is required for thumbor
        "pycurl==7.*,>=7.45.2" thumbor==7.7.* thumbor-aws==0.8.* tc_prometheus==2.* \
    ##
    ## Optional extensions
    ##
    ## `gifsicle` is a Thumbor requirement for better processing of GIF images
    && apk add --quiet --no-cache gifsicle \
    # Cleanup
    && apk del .build-deps

ARG TZ='UTC'
ENV TZ=$TZ

#These params meant to be set by CI
ARG BUILD_DATE=Undefined
ENV BUILD_DATE=$BUILD_DATE
RUN echo $BUILD_DATE
ARG BUILD_FINGERPRINT=Undefined
ENV BUILD_FINGERPRINT=$BUILD_FINGERPRINT
RUN echo $BUILD_FINGERPRINT

ENV LOG_LEVEL="warning"
ENV PORT="8888"
ENV NUM_PROCESSES=0

COPY ./docker/config/thumbor/thumbor.conf.tpl /usr/local/etc/thumbor.conf.tpl
COPY --chmod=0755 ./docker/config/etc/docker-entrypoint.sh /docker-entrypoint.sh

RUN set -eux \
    # /data/ dir is used by thumbor
    && mkdir /data/ \
    && mkdir /docker-entrypoint.init.d/ \
    && thumbor --version \
    && envtpl --help \
    && jpegtran -version \
    && gifsicle --version


WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/framework ./
#COPY --from=martin_builder --chown=nobody:root /usr/local/cargo/bin/martin ./bin/martin
#COPY --from=martin_builder --chown=nobody:root /usr/local/cargo/bin/martin-cp ./bin/martin-cp

# Enable nobody user
#RUN set -eux \
#    && chown -R nobody:nogroup /usr/local/etc/ /data/ /docker-entrypoint.init.d/
#USER nobody

#ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
#CMD ["thumbor"]
#
#EXPOSE ${PORT}
#HEALTHCHECK --timeout=15s CMD curl --silent --fail http://127.0.0.1:${PORT}/healthcheck

USER nobody
EXPOSE 80
ENV PORT=80

CMD ["/app/bin/server"]

# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"

