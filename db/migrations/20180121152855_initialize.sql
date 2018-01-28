-- migrate:up
CREATE TABLE subscribers (
    id INTEGER PRIMARY KEY,
    telegram_id INTEGER NOT NULL,
    notificationday INTEGER NOT NULL,
    notificationtime INTEGER NOT NULL
);

-- migrate:down
DROP TABLE subscribers
