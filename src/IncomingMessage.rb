# frozen_string_literal: true

##
# This class represents an incoming telegram
# bot message.
class IncomingMessage
  attr_reader :text, :author, :chat, :orig_obj

  @text = nil
  @author = nil
  @chat = nil
  @orig_obj = nil
  def initialize(text, author, chat, orig_obj)
    @text = text
    @author = author
    @chat = chat
    @orig_obj = orig_obj
  end
end
