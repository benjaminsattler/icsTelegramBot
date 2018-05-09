class MessageSender

    @bot = nil
    def initialize(bot)
        @bot = bot
    end

    def process(text, chatId, reply_markup = nil, silent = false)
        log("silent is #{silent} for #{text}") if silent
        reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /help /setday /botstatus), %w(/unsubscribe /events /settime /mystatus)], one_time_keyboard: false) if reply_markup.nil?
        begin
            @bot.api.send_message(chat_id: chatId, text: text, reply_markup: reply_markup, disable_notification: silent)
        rescue Exception => e
            log("Exception received #{e}")
        end
    end
end
