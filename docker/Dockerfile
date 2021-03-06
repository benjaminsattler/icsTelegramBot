# base system image with all deps
FROM ruby:2.4.4 AS base

ARG GIT_TAG=unknown
ARG GIT_REPO=unknown
ARG BUILD_TIME=unknown
ARG BUILD_USER=unknown

COPY ./Gemfile ./
# BUNDLE_FORCE_RUBY_PLATFORM needs to be set
# because of https://github.com/protocolbuffers/protobuf/issues/3925
# for google-cloud-logging
RUN apt-get update && \
    apt-get install -v ruby-dev build-base sqlite-dev mysql-dev libc6-compat tzdata && \
    rm -rf /var/cache/apt/ && \
    rm -rf /var/cache/apt/ && \
    wget -O /usr/local/bin/dbmate https://github.com/amacneil/dbmate/releases/download/v1.4.1/dbmate-linux-amd64 && \
    chmod +x /usr/local/bin/dbmate && \
    BUNDLE_FORCE_RUBY_PLATFORM=1 bundle install --without="development testing"
ENTRYPOINT [ "/usr/local/bin/dbmate" ]
ENV ICSBOT_GIT_TAG="$GIT_TAG" \
    ICSBOT_GIT_URL="$GIT_REPO" \
    ICSBOT_BUILD_TIME="$BUILD_TIME" \
    ICSBOT_BUILD_USER="$BUILD_USER"
LABEL "net.benjaminsattler.icsbot.git_tag"="$GIT_TAG" \
      "net.benjaminsattler.icsbot.git_url"="$GIT_REPO" \
      "net.benjaminsattler.icsbot.build_time"="$BUILD_TIME" \
      "net.benjaminsattler.icsbot.build_user"="$BUILD_USER"
VOLUME /assets

# development image
FROM base AS development

EXPOSE 1234 26162
COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    BUNDLE_FORCE_RUBY_PLATFORM=1 bundle install --with="development"
VOLUME /db /app
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/app/src/server.rb" ]

# testing image
FROM development AS testing
RUN BUNDLE_FORCE_RUBY_PLATFORM=1 bundle install --with="testing"
ENV ICSBOT_ENV=testing
WORKDIR /app/
ENTRYPOINT ["rspec"]
CMD [ "/app/spec/" ]

# linting image
FROM cagedata/rubocop AS linting
RUN gem install rubocop-rspec

# production image
FROM base AS production
MAINTAINER "Benjamin Sattler <bsattler.inbox@gmail.com>"
ARG TMPFS=unknown

COPY ./docker/entrypoint.sh /entrypoint.sh

WORKDIR /app/
ADD --chown="root:root" $TMPFS /app/
RUN chmod +x /entrypoint.sh && \
    chown -R root:root /app/

ENV ICSBOT_ENV=production
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/app/src/server.rb" ]
