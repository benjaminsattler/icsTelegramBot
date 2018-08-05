-- migrate:up
CREATE TABLE eventslists(
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    display_name TEXT NOT NULL,
    filename TEXT NOT NULL
);

ALTER TABLE subscribers ADD COLUMN eventlist_id INTEGER REFERENCES eventslists(id);
INSERT INTO eventslists(display_name, filename) VALUES ('default list', 'somefile.ics');

-- migrate:down
ALTER TABLE subscribers DROP COLUMN eventlist_id;
DROP TABLE eventslists;
