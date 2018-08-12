FROM ruby:2.4.4-alpine3.7
RUN apk update && apk add -v ruby-dev build-base sqlite-dev mysql-dev
VOLUME /app
VOLUME /assets
ENV ICSBOT_ENV=testing
WORKDIR /app
CMD bundle install && /app/bin/server --main=MainThread
