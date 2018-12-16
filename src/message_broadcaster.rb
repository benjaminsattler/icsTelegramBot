# frozen_string_literal: true

##
# This class provides the means to send
# a message with the telegram bot API.
class MessageBroadcaster
  @bot = nil
  @statistics = nil

  def initialize(message_sender, persistence)
    @message_sender = message_sender
    @persistence = persistence
  end

  def process(text)
    eventlists = @persistence.calendars
    subscribers = Set.new
    eventlists.each_key do |id|
      subs = @persistence.all_subscribers(id)
      subscribers.merge(
        subs.map { |sub| sub[:telegram_id] }
      )
    end
    subscribers.each do |subscriber|
      @message_sender.process(
        text,
        subscriber,
        nil,
        false
      )
    end
  end
end
