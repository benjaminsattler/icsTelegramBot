FROM ruby:2.4.4-alpine3.7

COPY ./Gemfile ./Gemfile.lock ./
WORKDIR /app
VOLUME /app
RUN apk update && \
    apk add -v ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without=development
ENV ICSBOT_ENV=testing
ENTRYPOINT ["rspec"]
