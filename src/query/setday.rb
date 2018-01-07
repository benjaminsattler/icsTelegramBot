require 'query/query'

class SetDayQuery < Query
    
    def initialize(opts)
        super(opts)
    end

    def respond
        response = I18n.t('setday.command_inline', response: @given_data.first)
        @bot.bot_instance.api.editMessageText(chat_id: @chat_id, message_id: @message_id, text: response, reply_markup: self.getKeyboard)
    end

    def respondTo(msg)
        @given_data.push(msg.data)
        self.finish
    end
    
    def complete?
        false
    end

    def start
        response = I18n.t('setday.command_inline', response: '__')
        id = @bot.pushMessage(response, @chat_id, self.getKeyboard)
        @message_id = id['result']['message_id'] unless id['result'].nil? or id['result']['message_id'].nil?
        @bot.storePendingQuery(@message_id, self)
    end
    
    def finish
        self.respond
        @bot.bot_instance.api.editMessageReplyMarkup(chat_id: @chat_id, message_id: @message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: nil) )
        @bot.removePendingQuery(self)
        @bot.handleSetDayMessage("/setday #{@given_data.first}", @user_id, @chat_id)
    end

    def getKeyboard
        btns = (0..14).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{n}", callback_data: "#{n}") }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..4], btns[5..9], btns[10..14]])
    end
end
