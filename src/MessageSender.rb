# frozen_string_literal: true

##
# This class provides the means to send
# a message with the telegram bot API.
class MessageSender
  @bot = nil
  def initialize(bot)
    @bot = bot
  end

  def process(text, chat_id, reply_markup = nil, silent = false)
    log("silent is #{silent} for #{text}") if silent
    if reply_markup.nil?
      reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [
          %w[/subscribe /help /setday /botstatus],
          %w[/unsubscribe /events /settime /mystatus]
        ],
        one_time_keyboard: false
      )
    end
    begin
      @bot.api.send_message(
        chat_id: chat_id,
        text: text,
        reply_markup: reply_markup,
        disable_notification: silent
      )
    rescue StandardError => e
      log("StandardError received #{e}")
    end
  end
end
