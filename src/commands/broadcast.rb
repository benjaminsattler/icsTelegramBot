# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'util'

require 'i18n'

##
# This class represents the /mystatus command
# given by the user.
class BroadcastCommand < Command
  def initialize(message_broadcaster, message_sender)
    super(message_sender)
    @message_broadcaster = message_broadcaster
  end

  def process(msg, _userid, chatid, _silent)
    _command, *args = msg.split(/\s+/)
    message = args.join(' ')
    if message.empty?
      @message_sender.process(
        I18n.t('errors.broadcast.empty_message'),
        chatid
      )
    end
    @message_broadcaster.process(args.join(' '))
  end
end
