# frozen_string_literal: true

##
# This class provides the means to send
# a message with the telegram bot API.
class MessageBroadcaster
  @statistics = nil

  def initialize(message_sender)
    @message_sender = message_sender
  end

  def process(msg)
    @message_sender.process(msg)
  end
end
