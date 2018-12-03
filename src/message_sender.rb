# frozen_string_literal: true

##
# This class provides the means to send
# a message with the telegram bot API.
class MessageSender
  @bot = nil
  @statistics = nil

  def initialize(bot, statistics)
    @bot = bot
    @statistics = statistics
  end

  def process(text, chat_id, reply_markup = nil, silent = false)
    log("silent is #{silent} for #{text}") if silent
    @statistics.sent_msg
    if reply_markup.nil?
      reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: default_keyboard_markup(chat_id),
        one_time_keyboard: false
      )
    end
    begin
      @bot.bot_instance.api.send_message(
        chat_id: chat_id,
        text: text,
        reply_markup: reply_markup,
        disable_notification: silent
      )
    rescue StandardError => e
      log("StandardError received #{e}")
    end
  end

  def default_keyboard_markup(chat_id)
    if @bot.admin_user?(chat_id)
      [
        %w[/subscribe /setday /help /botstatus],
        %w[/unsubscribe /settime /events /mystatus]
      ]
    else
      [
        %w[/subscribe /setday /help],
        %w[/unsubscribe /settime /events /mystatus]
      ]
    end
  end
end
