FROM ruby:2.4.4-alpine3.7

ARG GIT_TAG=unknown
ARG GIT_REPO=unknown
ARG BUILD_TIME=unknown
ARG BUILD_USER=unknown
ARG TMPFS=unknown
MAINTAINER "Benjamin Sattler <bsattler.inbox@gmail.com>"

COPY ./Gemfile ./Gemfile.lock ./

RUN apk update && \
    apk add -v --no-cache ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without="testing development" && \
    apk del build-base

WORKDIR /app/
ADD --chown="root:root" $TMPFS /app/
RUN chown -R root:root /app/

VOLUME /assets
VOLUME /log
VOLUME /config
LABEL net.benjaminsattler.icsbot.git_tag=$GIT_TAG
LABEL net.benjaminsattler.icsbot.git_url=$GIT_REPO
LABEL net.benjaminsattler.icsbot.build_time=$BUILD_TIME
LABEL net.benjaminsattler.icsbot.build_user=$BUILD_USER
#CMD ["ls", "-l", "/", "/app", "/app/bin" , "/app/src"]
CMD [ "/app/bin/server", "--main=MainThread", "--log=/log/muell.log" ]
