# frozen_string_literal: true

##
# This class provides the means to send
# a message with the telegram bot API.
class MessageSender
  @bot = nil
  @api = nil
  @statistics = nil
  @message_log = nil

  def initialize(bot, api, statistics, message_log)
    @bot = bot
    @api = api
    @statistics = statistics
    @message_log = message_log
  end

  def process(msg)
    # if reply_markup.nil?
    #  reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
    #    keyboard: default_keyboard_markup(chat_id),
    #    one_time_keyboard: false
    #  )
    # end
    begin
      sent_messages = msg.send(@api)
    rescue StandardError => e
      log("StandardError received #{e}")
    end
    sent_messages.each do |sent_message|
      @statistics.sent_msg
      @message_log.add(sent_message)
    end
    sent_messages
  end

  def default_keyboard_markup(chat_id)
    if @bot.admin_user?(chat_id)
      [
        %w[/subscribe /setday /help /botstatus /download],
        %w[/unsubscribe /settime /events /mystatus /broadcast]
      ]
    else
      [
        %w[/subscribe /setday /help],
        %w[/unsubscribe /settime /events /mystatus]
      ]
    end
  end
end
