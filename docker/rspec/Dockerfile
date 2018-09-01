FROM muell:latest
COPY Gemfile .
WORKDIR /app
VOLUME /app
RUN apk update && \
    apk add -v ruby-dev build-base sqlite-dev mysql-dev && \
    bundle install --without=development
ENV ICSBOT_ENV=testing
ENTRYPOINT ["rspec"]
