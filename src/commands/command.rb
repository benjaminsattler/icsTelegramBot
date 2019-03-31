# frozen_string_literal: true

##
# This class represents the base class
# for any command given by the user.
class Command
  def initialize(message_sender, api = nil)
    @message_sender = message_sender
    @api = api
  end

  def process(_msg, _userid, _chatid, _silent)
    raise NotImplementedError
  end
end
