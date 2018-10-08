# base system image with all deps
FROM ruby:2.4.4-alpine3.7 AS base

COPY ./Gemfile ./Gemfile.lock ./

COPY --from=amacneil/dbmate /usr/local/bin/dbmate /usr/local/bin/dbmate
RUN apk update && \
    apk add -v --no-cache ruby-dev build-base sqlite-dev mysql-dev libc6-compat && \
    bundle install --without="development testing"
ENTRYPOINT [ "/usr/local/bin/dbmate" ]
VOLUME /assets /log

# development image
FROM base AS development

EXPOSE 1234 26162
COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    bundle install --with="development" && \
    apk del build-base
VOLUME /db /app
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/app/bin/server", "--main=MainThread" ]

# testing image
FROM development AS testing
RUN bundle install --with="testing"
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
ARG GIT_TAG=unknown
ARG GIT_REPO=unknown
ARG BUILD_TIME=unknown
ARG BUILD_USER=unknown
ARG TMPFS=unknown

COPY ./docker/entrypoint.sh /entrypoint.sh

WORKDIR /app/
ADD --chown="root:root" $TMPFS /app/
RUN chmod +x /entrypoint.sh && \
    chown -R root:root /app/

LABEL net.benjaminsattler.icsbot.git_tag=$GIT_TAG
LABEL net.benjaminsattler.icsbot.git_url=$GIT_REPO
LABEL net.benjaminsattler.icsbot.build_time=$BUILD_TIME
LABEL net.benjaminsattler.icsbot.build_user=$BUILD_USER

ENV ICSBOT_ENV=production
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/app/bin/server", "--main=MainThread" , "--log=/log/icsbot.log"]
