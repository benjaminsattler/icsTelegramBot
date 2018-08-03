FROM amacneil/dbmate
VOLUME /db
ENV DATABASE_URL=sqlite:////db/dev.db
CMD [ "--migrations-dir", "/db/migrations", "up" ]
