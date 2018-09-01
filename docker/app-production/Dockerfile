FROM ruby:2.4.4-alpine3.7
COPY ./Gemfile .
RUN apk update && \
    apk add -v ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without="testing development"

WORKDIR /app/
VOLUME /app
VOLUME /assets
VOLUME /log

CMD [ "/app/bin/server", "--main=MainThread", "--log=/log/bot.log" ]
