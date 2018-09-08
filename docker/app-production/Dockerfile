FROM ruby:2.4.4-alpine3.7
MAINTAINER "Benjamin Sattler <bsattler.inbox@gmail.com>"
ARG GIT_TAG=unknown
ARG GIT_REPO=unknown
ARG BUILD_TIME=unknown
ARG BUILD_USER=unknown

WORKDIR /app/
COPY ./Gemfile .
COPY ./bin/ .
COPY ./lang/ .
COPY ./scripts/ .
COPY ./src/ .
RUN apk update && \
    apk add -v ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without="testing development"

VOLUME /assets
VOLUME /log
VOLUME /config
LABEL net.benjaminsattler.icsbot.git_tag=$GIT_TAG
LABEL net.benjaminsattler.icsbot.git_url=$GIT_REPO
LABEL net.benjaminsattler.icsbot.build_time=$BUILD_TIME
LABEL net.benjaminsattler.icsbot.build_user=$BUILD_USER

CMD [ "/app/bin/server", "--main=MainThread", "--log=/log/muell.log" ]
