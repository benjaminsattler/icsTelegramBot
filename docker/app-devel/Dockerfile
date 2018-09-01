ARG DEBUGGER_PORT
FROM muell:latest
COPY ./Gemfile .
RUN bundle install --with=development

WORKDIR /app/
VOLUME /app
VOLUME /assets
VOLUME /log

EXPOSE $DEBUGGER_PORT
EXPOSE 26162
ENTRYPOINT [ "rdebug-ide", "--host", "0.0.0.0", "--port", "1234", "--dispatcher-port", "26162", "--" ]
CMD [ "/app/bin/server", "--main=MainThread" ]
