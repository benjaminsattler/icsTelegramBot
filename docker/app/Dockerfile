ARG DEBUGGER_PORT
FROM ruby:2.4.4-alpine3.7
COPY ./Gemfile .
RUN apk update && \
    apk add -v ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without=testing

WORKDIR /app/
VOLUME /app
VOLUME /assets
VOLUME /log

EXPOSE $DEBUGGER_PORT
EXPOSE 26162
ENTRYPOINT [ "rdebug-ide", "--host", "0.0.0.0", "--port", "1234", "--dispatcher-port", "26162", "--" ]
CMD [ "/app/bin/server", "--main=MainThread" ]
