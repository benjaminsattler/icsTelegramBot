# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'messages/broadcast_message'
require 'messages/message'
require 'util'

require 'i18n'

##
# This class represents the /mystatus command
# given by the user.
class BroadcastCommand < Command
  def process(msg, _userid, chatid, _silent)
    _command, *args = msg.split(/\s+/)
    message = args.join(' ')
    if message.empty?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.broadcast.empty_message',
          i18nparams: {},
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end

    datastore = Container.get(:dataStore)
    recv_list = datastore.all_subscribers.map { |sub| sub[:telegram_id] }
    message = args.join(' ')
    @message_sender.process(
      BroadcastMessage.new(
        i18nkey: 'broadcast.message',
        i18nparams: {
          message: message
        },
        recv_list: recv_list,
        markup: nil
      )
    )
  end
end
