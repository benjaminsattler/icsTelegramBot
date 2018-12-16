# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'util'

require 'i18n'

##
# This class represents the /mystatus command
# given by the user.
class BroadcastCommand < Command
  def initialize(message_broadcaster)
    @message_broadcaster = message_broadcaster
  end

  def process(msg, _userid, _chatid, _silent)
    _command, *args = msg.split(/\s+/)

    @message_broadcaster.process(args.join(' '))
  end
end
