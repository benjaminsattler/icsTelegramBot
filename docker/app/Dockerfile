FROM ruby:2.4.4-alpine3.7
RUN apk update && apk add -v ruby-dev build-base sqlite-dev mysql-dev
VOLUME /app
VOLUME /assets
VOLUME /log
WORKDIR /app
EXPOSE 1234
EXPOSE 26162
CMD bundle install --without=testing && rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- /app/bin/server --main=MainThread
