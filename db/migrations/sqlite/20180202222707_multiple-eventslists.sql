-- migrate:up
CREATE TABLE eventslists(
    id INTEGER PRIMARY KEY,
    display_name TEXT NOT NULL,
    filename TEXT NOT NULL
);

ALTER TABLE subscribers ADD COLUMN eventlist_id INTEGER REFERENCES eventslists(id);
INSERT INTO eventslists(display_name, filename) VALUES ('default list', '/assets/default.ics');
UPDATE subscribers SET eventlist_id=last_insert_rowid();

-- migrate:down
PRAGMA foreign_keys=off;

ALTER TABLE subscribers RENAME TO subscribers_temp;
CREATE TABLE subscribers (
    id INTEGER PRIMARY KEY,
    telegram_id INTEGER NOT NULL,
    notificationday INTEGER NOT NULL,
    notificationtime INTEGER NOT NULL
);

INSERT INTO subscribers (id, telegram_id, notificationday, notificationtime)
  SELECT id, telegram_id, notificationday, notificationtime
  FROM subscribers_temp;
 
 DROP table subscribers_temp;

 
 PRAGMA foreign_keys=on;

 DROP TABLE eventslists;
