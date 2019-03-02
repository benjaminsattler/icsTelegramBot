# frozen_string_literal: true

require 'json'
require 'messages/sent_message'

##
# This class logs sent messages
class MessageLog
  def initialize(persistence)
    @persistence = persistence
  end

  def add(message)
    @persistence.add_to_message_log(
      telegram_id: message.id_recv,
      msg_id: message.id,
      message_timestamp: message.datetime,
      i18nkey: message.i18nkey,
      i18nparams: JSON.dump(message.i18nparams)
    )
  end
end
