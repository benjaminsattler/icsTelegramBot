-- migrate:up
CREATE TABLE message_log(
  id_message_log INT NOT NULL AUTO_INCREMENT,
  telegram_id INT NOT NULL,
  msg_id INT NULL,
  message_timestamp DATETIME NOT NULL,
  i18nkey VARCHAR(255) NOT NULL,
  i18nparams TEXT NULL,
  PRIMARY KEY(id_message_log)
);

-- migrate:down
DROP TABLE message_log;
